class TECSUnitPlugin < CellPlugin



  # プラグイン引数名 => Proc
  # @@cell_list = {}      # gen_cdl_file'ed list to avoid duplicate generation
  # @@signature_list = {}

  #=== CellPlugin# initialize
  #cell::     Cell        セル（インスタンス）
  # このメソッドは、セルの構文解析が終わったところで呼び出される
  # この段階では意味解析が終わっていない
  def initialize( cell, option )
    dbgPrint "  #{self.class.name}: initialzie=#{cell.get_name} option=#{option}\n"
    super #/おそらく親クラスのinitialize関数を呼び出している/
    @cell = cell

    @plugin_arg_str = CDLString.remove_dquote option
    # @plugin_arg_str = option.gsub( /\A"(.*)/, '\1' )    # 前後の "" を取り除く
    # @plugin_arg_str.sub!( /(.*)"\z/, '\1' )
    @plugin_arg_list = {}
  end

  def gen_cdl_file file # celltype"tTECSUnit"を定義。呼び口の定義がテストターゲットによる
    # tTECSUnit の定義を生成する
    file.print <<EOT

celltype tTECSUnit {
    entry sTECSUnit eUnit;

    /*----- TECSInfo -----*/
    call nTECSInfo::sTECSInfo cTECSInfo;
    [dynamic,optional]
      call  nTECSInfo::sNamespaceInfo cNSInfo;
    [dynamic,optional]
      call  nTECSInfo::sRegionInfo    cRegionInfo;
    [dynamic,optional]
      call  nTECSInfo::sCellInfo      cCellInfo;
    [dynamic,optional]
      call  nTECSInfo::sSignatureInfo cSignatureInfo;
    [dynamic,optional]
      call  nTECSInfo::sCelltypeInfo  cCelltypeInfo;
    [dynamic,optional]
      call  nTECSInfo::sVarDeclInfo   cVarDeclInfo;
    [dynamic,optional]
      call  nTECSInfo::sTypeInfo      cTypeInfo;
    /*----- TECSInfo -----*/

    /*----- RawEntryDescriptor -----*/
    [dynamic,optional]
      call  nTECSInfo::sRawEntryDescriptorInfo   cREDInfo;
    [dynamic,optional]
      call  nTECSInfo::sEntryInfo     cEntryInfo;
    /*----- RawEntryDescriptor -----*/

    /*----- TECSUnit test -----*/
      /* プラグインにより自動生成される */
EOT
    # 必要な呼び口記述を行う
    print_all_call_port( file, Namespace.get_root )

    file.print <<EOT
    /*----- TECSUnit test -----*/

    attr {
      int16_t LEN = 256;
    };
    var {
      void *data;
      [size_is(LEN)]
        char *cell_entry;
    };
EOT

    file.print <<EOT

};
EOT
  end

  def print_all_call_port file, namespace
    namespace.travers_all_signature{ |sig|
      if  sig.get_namespace_path.to_s =~ /nTECSInfo::/ || \
          sig.get_namespace_path.to_s =~ /::s.*Task.*/ || \
          sig.get_namespace_path.to_s =~ /::sAccessor/ || \
          sig.get_namespace_path.to_s =~ /::sTECSUnit/ || \
          sig.get_namespace_path.to_s =~ /::sJSMN/ || \
          sig.get_namespace_path.to_s =~ /::s.*Kernel/ || \
          sig.get_namespace_path.to_s =~ /::s.*Semaphore/ || \
          sig.get_namespace_path.to_s =~ /::s.*Eventflag/ || \
          sig.get_namespace_path.to_s =~ /::s.*Dataqueue/ || \
          sig.get_namespace_path.to_s =~ /::sInitialize.*/ || \
          sig.get_namespace_path.to_s =~ /::s.*VM/ || \
          sig.get_namespace_path.to_s =~ /::sMain/ || \
          sig.get_namespace_path.to_s =~ /::s.*Alarm/ || \
          sig.get_namespace_path.to_s =~ /::sFixedSizeMemoryPool/ || \
          sig.get_namespace_path.to_s =~ /::sMessageBuffer/ || \
          sig.get_namespace_path.to_s =~ /::sTerminateRoutineBody/ || \
          sig.get_namespace_path.to_s =~ /::s.*HandlerBody/ || \
          sig.get_namespace_path.to_s =~ /::sConfigInterrupt/ || \
          sig.get_namespace_path.to_s =~ /::sCyclic/ || \
          sig.get_namespace_path.to_s =~ /::sMalloc/ then
        # ignnore these signatures
      else
        file.print <<EOT
    [dynamic, optional]
      call #{sig.get_namespace_path.to_s} c#{sig.get_name[1..-1]};
EOT
      end
    }
  end

#################################################################################################

  def gen_ep_func_body( file, b_singleton, ct_name, global_ct_name, sig_name, ep_name, func_name, func_global_name, func_type, paramSet )

    @test_case = ""    #テストケースを扱うための変数
    @boundary_flag = [] #テストケースにboundary_valがあるかを判定
    @EP_flag = [] #テストケースにEP_boundary_valがあるかを判定
    test_method_flag = 0 # 1ならBVT、２ならEPT、

    if func_name.to_s == "main" then
      print_main( file, Namespace.get_root )
    end

    if func_name.to_s == "boundary_value_test" then
      test_method_flag = 1
      parse_json( file, Namespace.get_root, test_method_flag ) #テストケース解析
      if @boundary_flag.find { |number| number == 1} == 1 then
        print_boundary_value_test( file, Namespace.get_root )
      end
      test_method_flag = 0
    end

    if func_name.to_s == "equivalence_partitioning_test" then
      test_method_flag = 2
      parse_json( file, Namespace.get_root, test_method_flag )
      if @EP_flag.find { |number| number == 1} == 1 then
        print_equivalence_partitioning_test( file, Namespace.get_root )
      end
      test_method_flag = 0
    end

  end

  #
  # target.jsonを読み取り、特定のキーワードを含む一文があるかどうかをチェック
  #

  def parse_json( file, namespace, flag )
    require 'json'
    file = File.open("target.json")
    @test_case = JSON.load(file)

    # 
    # 以下のfor文を増やすことで、チェックするキーワードを増やせる
    # キーワードを増やした場合は、それに伴い追加で配列が必要
    #
    
    if flag == 1 then
      for target_count in 1..@test_case.length do
        if @test_case["target"+target_count.to_s].include?("boundary_val") then
          @boundary_flag[target_count-1] = 1
        else
          @boundary_flag[target_count-1] = 0
        end
      end
    elsif flag == 2 then
      for target_count in 1..@test_case.length do
        if @test_case["target"+target_count.to_s].include?("EP_boundary_val") then
          @EP_flag[target_count-1] = 1
        else
          @EP_flag[target_count-1] = 0
        end 
      end
    end

  end

  def print_main( file, namespace )
    file.print <<EOT
  CELLCB *p_cellcb;
  if (VALID_IDX(idx)) {
    p_cellcb = GET_CELLCB(idx);
  }
  else {
    /* エラー処理をここに記述します */
  } /* end if VALID_IDX(idx) */

  printf("\\n--- TECSUnit ---\\n" );
  void *rawDesc;
EOT
    # 1.descriptorの記述
    print_desc( file, Namespace.get_root )

    file.print <<EOT
  sprintf( VAR_cell_entry, "%s.%s", cell_path, entry_path );
  getRawEntryDescriptor( p_cellcb, VAR_cell_entry, &rawDesc, signature_path );
EOT
    
    # 2.本体コードの記述
    print_branch_sig( file, Namespace.get_root )
  end

  # 1.descriptorの記述
  def print_desc( file, namespace )
    namespace.travers_all_signature{ |sig|
      if  sig.get_namespace_path.to_s =~ /nTECSInfo::/ || \
          sig.get_namespace_path.to_s =~ /::s.*Task.*/ || \
          sig.get_namespace_path.to_s =~ /::sAccessor/ || \
          sig.get_namespace_path.to_s =~ /::sTECSUnit/ || \
          sig.get_namespace_path.to_s =~ /::sJSMN/ || \
          sig.get_namespace_path.to_s =~ /::s.*Kernel/ || \
          sig.get_namespace_path.to_s =~ /::s.*Semaphore/ || \
          sig.get_namespace_path.to_s =~ /::s.*Eventflag/ || \
          sig.get_namespace_path.to_s =~ /::s.*Dataqueue/ || \
          sig.get_namespace_path.to_s =~ /::sInitialize.*/ || \
          sig.get_namespace_path.to_s =~ /::s.*VM/ || \
          sig.get_namespace_path.to_s =~ /::sMain/ || \
          sig.get_namespace_path.to_s =~ /::s.*Alarm/ || \
          sig.get_namespace_path.to_s =~ /::sFixedSizeMemoryPool/ || \
          sig.get_namespace_path.to_s =~ /::sMessageBuffer/ || \
          sig.get_namespace_path.to_s =~ /::sTerminateRoutineBody/ || \
          sig.get_namespace_path.to_s =~ /::s.*HandlerBody/ || \
          sig.get_namespace_path.to_s =~ /::sConfigInterrupt/ || \
          sig.get_namespace_path.to_s =~ /::sCyclic/ || \
          sig.get_namespace_path.to_s =~ /::sMalloc/ then
        # ignnore these signatures
      else
        file.print <<EOT
  Descriptor( #{sig.get_name} ) #{sig.get_name[1..-1]}Desc;
EOT
      end
    }
  end

  # 2.本体コードの記述
  def print_branch_sig( file, namespace )
    flag = true
    namespace.travers_all_signature{ |sig|
      if  sig.get_namespace_path.to_s =~ /nTECSInfo::/ || \
          sig.get_namespace_path.to_s =~ /::s.*Task.*/ || \
          sig.get_namespace_path.to_s =~ /::sAccessor/ || \
          sig.get_namespace_path.to_s =~ /::sTECSUnit/ || \
          sig.get_namespace_path.to_s =~ /::sJSMN/ || \
          sig.get_namespace_path.to_s =~ /::s.*Kernel/ || \
          sig.get_namespace_path.to_s =~ /::s.*Semaphore/ || \
          sig.get_namespace_path.to_s =~ /::s.*Eventflag/ || \
          sig.get_namespace_path.to_s =~ /::s.*Dataqueue/ || \
          sig.get_namespace_path.to_s =~ /::sInitialize.*/ || \
          sig.get_namespace_path.to_s =~ /::s.*VM/ || \
          sig.get_namespace_path.to_s =~ /::sMain/ || \
          sig.get_namespace_path.to_s =~ /::s.*Alarm/ || \
          sig.get_namespace_path.to_s =~ /::sFixedSizeMemoryPool/ || \
          sig.get_namespace_path.to_s =~ /::sMessageBuffer/ || \
          sig.get_namespace_path.to_s =~ /::sTerminateRoutineBody/ || \
          sig.get_namespace_path.to_s =~ /::s.*HandlerBody/ || \
          sig.get_namespace_path.to_s =~ /::sConfigInterrupt/ || \
          sig.get_namespace_path.to_s =~ /::sCyclic/ || \
          sig.get_namespace_path.to_s =~ /::sMalloc/ then
      # ignnore these signatures
      else

        if flag then # signature１つ目
          flag = false
          file.print <<EOT

  if( !strcmp(signature_path, "#{sig.get_name}" ) ){
    setRawEntryDescriptor( #{sig.get_name[1..-1]}Desc, #{sig.get_name}, rawDesc );
    c#{sig.get_name[1..-1]}_set_descriptor( #{sig.get_name[1..-1]}Desc );
EOT
          print_branch_func( file, sig )
          file.print <<EOT
  }
EOT
        else # signature2つ目以降
          file.print <<EOT
  else if( !strcmp(signature_path, "#{sig.get_name}" ) ){
    setRawEntryDescriptor( #{sig.get_name[1..-1]}Desc, #{sig.get_name}, rawDesc );
    c#{sig.get_name[1..-1]}_set_descriptor( #{sig.get_name[1..-1]}Desc );
EOT
          print_branch_func( file, sig )
          file.print <<EOT
  }
EOT
        end
      end
    }
  end

  def print_branch_func( file, signature ) # ここでのsignatureは全てのsigunatureを探索し、正規表現に引っかからなかったもの一つ一つ
    str = ""
    paramSet = ""
    param = ""
    exp_val = ""
    flag = true # 初回のみtrue以降はelse ifを使いたい。
    # out引数のカウント
    int_count = 0
    double_count = 0
    char_count = 0

    signature.get_function_head_array.each{ |func| # itemsに入ってるitemを一つ一つfuncとして実行(?)
      paramSet = ""
      exp_val = ""
      # 期待値のパラメータを取得する
      if func.get_return_type.get_type_str.include?("void") then
        exp_val = ""
      elsif func.get_return_type.get_type_str.include?("double") || func.get_return_type.get_type_str.include?("float") then
        exp_val = "exp_val->" + "data.mem_#{func.get_return_type.get_type_str.sub(/\*/, '_buf').sub('const ', '').sub('struct ', '').sub('32_t', '').sub('64_t', '')}"
      else
        exp_val = "exp_val->" + "data.mem_#{func.get_return_type.get_type_str.sub(/\*/, '_buf').sub('const ', '').sub('struct ', '')}"
      end
      # 関数の引数パラメータを取得する
      int_count, double_count, char_count = 0,0,0
      n = func.get_paramlist.get_items.length #lengthは配列のサイズを返す
      func.get_paramlist.get_items.each_with_index { |paramDecl, idx| # idxには0,1,2,と処理の回数ごとに大きくなる値が入る
        param = paramDecl.get_type.get_type_str
      # TODO:ここから
        if param.include?("*") && !param.include?("const") then # paramが[out]指定子付きと判断
          if param.include?("int") || param.include?("INT") ||\
             param.include?("short") || param.include?("SHORT") ||\
             param.include?("long") || param.include?("LONG") then
            # voidポインタのインクリメントは１になるのでこの実装でOK
            paramSet.concat("(int *) ( VAR_data + sizeof(int)*#{int_count} + sizeof(double)*#{double_count} + sizeof(char)*#{char_count} )")
            int_count += 1
          elsif param.include?("double") || param.include?("float") then
            paramSet.concat("(double *) ( VAR_data + sizeof(int)*#{int_count} + sizeof(double)*#{double_count} + sizeof(char)*#{char_count} )")
            double_count += 1
          elsif param.include?("char") || param.include?("CHAR") then
            paramSet.concat("(char *) ( VAR_data + sizeof(int)*#{int_count} + sizeof(double)*#{double_count} + sizeof(char)*#{char_count} )")
            char_count += 1
          end
      # ここまで
        else #[in]指定子の場合
          if param.include?("struct") then
            paramSet.concat("&arguments[#{idx}].data.mem_#{param.sub(/\*/, '_buf').sub('const ', '').sub('struct ', '')}")
          else
            if param.include?("double") || param.include?("float") then
              paramSet.concat("arguments[#{idx}].data.mem_#{param.sub(/\*/, '_buf').sub('const ', '').sub('32_t', '').sub('64_t', '')}")
            elsif param.include?("char") || param.include?("CHAR") then
              paramSet.concat("arguments[#{idx}].data.mem_#{param.sub(/\*/, '_buf').sub('const ', '').sub('_t', '')}")
            else
              paramSet.concat("arguments[#{idx}].data.mem_#{param.sub(/\*/, '_buf').sub('const ', '')}")
            end
          end
        end
        if idx + 1 < n then
          paramSet.concat(", ")
        end
      }
      print_call_desc( file, func.get_name.to_s, exp_val, signature, paramSet, int_count, double_count, char_count, flag )
      flag = false
    }
  end

  def print_call_desc( file, f_name, exp_val, signature, paramSet, int_count, double_count, char_count, flag )
    if flag then
      file.print <<EOT
      if( !strcmp( function_path, "#{f_name}" ) ){
        printf("Call #{f_name}\\n");
EOT
    else
      file.print <<EOT
      else if( !strcmp( function_path, "#{f_name}" ) ){
        printf("Call #{f_name}\\n");
EOT
    end

    if int_count + double_count + char_count > 0 then
      file.print <<EOT
        VAR_data = malloc( sizeof(int)*#{int_count} + sizeof(double)*#{double_count} + sizeof(char)*#{char_count} );
EOT
    end

    if exp_val == "" then
      file.print <<EOT
        c#{signature.get_name[1..-1]}_#{f_name}( #{paramSet} );
        return 0;
EOT
    else
      file.print <<EOT
        if( #{exp_val} == c#{signature.get_name[1..-1]}_#{f_name}( #{paramSet} ) ){
/*            return 0; */
            printf("\\nResult：OK\\n");
            printf("[ Expected result ]\\n");
            strcat(result_str, "| Arg Test | #{signature.get_name[1..-1]}_#{f_name} | **passed ✓** |\\n");
        }else{
/*            return -1; */
            printf("\\nResult：NG\\n");
            printf("[ Unexpected result ]\\n");
            strcat(result_str, "| Arg Test | #{signature.get_name[1..-1]}_#{f_name} | **failed X** |\\n");
        }
EOT
    end

    if int_count + double_count + char_count > 0 then
      file.print <<EOT
        free( VAR_data );
EOT
    end
    out_check( file, int_count, double_count, char_count )
    file.print <<EOT
      }
EOT
  end

  # TODO:out指定子の確認を行いたい
  def out_check( file, int_count, double_count, char_count )
#     for i in 1..int_count
#       file.print <<EOT
#         printf("[out]：#{i}番目の整数型の値：");
#         printf("%d\\n", VAR_out_int[#{i-1}]);
# EOT
#     end

#     for i in 1..double_count
#       file.print <<EOT
#         printf("[out]：#{i}番目の浮動小数点型の値：");
#         printf("%f\\n", VAR_out_double[#{i-1}]);
# EOT
#     end

#     for i in 1..char_count
#       file.print <<EOT
#         printf("[out]：#{i}番目のchar型の値：");
#         printf("%s\\n", VAR_out_char[#{i-1}]);
# EOT
#     end

  end
  #=== 後ろの CDL コードを生成
  #プラグインの後ろの CDL コードを生成
  #file:: File:
  def self.gen_post_code( file )

  end

# プロトタイプ宣言をしています
  def gen_preamble( file, b_singleton, ct_name, global_ct_name )
    file.print <<EOT
ER getRawEntryDescriptor( CELLCB *p_cellcb, char_t *entry_path, void **rawEntryDesc, char_t *expected_signature );
EOT
  end

# 非受け口関数の生成
  def gen_postamble( file, b_singleton, ct_name, global_ct_name )
    file.print <<EOT
ER getRawEntryDescriptor( CELLCB *p_cellcb, char_t *entry_path, void **rawEntryDesc, char_t *expected_signature )
{
    Descriptor( nTECSInfo_sRawEntryDescriptorInfo ) rawEntryDescDesc;
    Descriptor( nTECSInfo_sEntryInfo )              entryDesc;
    ER     ercd;
    void *rawDesc;

    ercd = cTECSInfo_findRawEntryDescriptor( entry_path, &rawEntryDescDesc, &entryDesc );
    if( ercd != E_OK ){
      printf( "call_sTask: error cTECSInfo_findRawEntryDescriptor( entry_path=%s ) = %d", entry_path, ercd );
    }
    else {
#define NAME_LEN  (256)
        Descriptor( nTECSInfo_sSignatureInfo )  signatureDesc;
        char_t  name[ NAME_LEN ];

        cREDInfo_set_descriptor( rawEntryDescDesc );
        cEntryInfo_set_descriptor( entryDesc );
        cEntryInfo_getSignatureInfo( &signatureDesc );
        cSignatureInfo_set_descriptor( signatureDesc );
        ercd = cSignatureInfo_getName( name, NAME_LEN );
        if( ercd != E_OK ) {
            printf( "getRawEntryDescriptor: error cannot get signature name. expected: '%s'", expected_signature );
        }
        if( strcmp( name, expected_signature ) != 0 ){
            printf( "getRawEntryDescriptor: error signature name '%s' mismatch expecting '%s'", name, expected_signature );
            ercd = E_NOEXS;
        }
        cREDInfo_getRawDescriptor( 0, rawEntryDesc );
    }
    return ercd;
}
EOT

  end

  def print_boundary_value_test( file, namespace )
    file.print <<EOT
  CELLCB *p_cellcb;
  if (VALID_IDX(idx)) {
    p_cellcb = GET_CELLCB(idx);
  }
  else {
    /* エラー処理をここに記述します */
  } /* end if VALID_IDX(idx) */

  int i;
  int count = 0;
  int result_count[6] = { 0, 0, 0, 0, 0, 0 };
  int expect_result[6] = { 0, 1, 1, 1, 1, 0 };
  printf("\\n--- Boundary Value Test ---\\n\\n");
  for( i = 0; i < 2; i++ ){
    printf("boundary%d = %d\\n", i+1, boundary[i]);
  }
  void *rawDesc;
EOT
    print_desc( file, Namespace.get_root )

    file.print <<EOT
  sprintf( VAR_cell_entry, "%s.%s", cell_path, entry_path );
  getRawEntryDescriptor( p_cellcb, VAR_cell_entry, &rawDesc, signature_path );
EOT
    print_BVT_branch_sig( file, Namespace.get_root )
  end

  def print_BVT_branch_sig( file, namespace )
    flag = true
    namespace.travers_all_signature{ |sig|
      if  sig.get_namespace_path.to_s =~ /nTECSInfo::/ || \
          sig.get_namespace_path.to_s =~ /::s.*Task.*/ || \
          sig.get_namespace_path.to_s =~ /::sAccessor/ || \
          sig.get_namespace_path.to_s =~ /::sTECSUnit/ || \
          sig.get_namespace_path.to_s =~ /::sJSMN/ || \
          sig.get_namespace_path.to_s =~ /::s.*Kernel/ || \
          sig.get_namespace_path.to_s =~ /::s.*Semaphore/ || \
          sig.get_namespace_path.to_s =~ /::s.*Eventflag/ || \
          sig.get_namespace_path.to_s =~ /::s.*Dataqueue/ || \
          sig.get_namespace_path.to_s =~ /::sInitialize.*/ || \
          sig.get_namespace_path.to_s =~ /::s.*VM/ || \
          sig.get_namespace_path.to_s =~ /::sMain/ || \
          sig.get_namespace_path.to_s =~ /::s.*Alarm/ || \
          sig.get_namespace_path.to_s =~ /::sFixedSizeMemoryPool/ || \
          sig.get_namespace_path.to_s =~ /::sMessageBuffer/ || \
          sig.get_namespace_path.to_s =~ /::sTerminateRoutineBody/ || \
          sig.get_namespace_path.to_s =~ /::s.*HandlerBody/ || \
          sig.get_namespace_path.to_s =~ /::sConfigInterrupt/ || \
          sig.get_namespace_path.to_s =~ /::sCyclic/ || \
          sig.get_namespace_path.to_s =~ /::sMalloc/ then
      else

        sig.get_function_head_array.each{ |func|
          for i in 1..@test_case.length do
            if func.get_name.to_s == @test_case["target"+i.to_s]["function"] then
              signature_checker = 1
              break
            end
          end

          if signature_checker == 1 then
            if flag then
              flag = false
              file.print <<EOT
  if( !strcmp(signature_path, "#{sig.get_name}" ) ){
    setRawEntryDescriptor( #{sig.get_name[1..-1]}Desc, #{sig.get_name}, rawDesc );
    c#{sig.get_name[1..-1]}_set_descriptor( #{sig.get_name[1..-1]}Desc );
EOT
              print_BVT_branch_func( file, sig )
              file.print <<EOT
  }
EOT
            else
              file.print <<EOT
  else if( !strcmp(signature_path, "#{sig.get_name}") ){
    setRawEntryDescriptor( #{sig.get_name[1..-1]}Desc, #{sig.get_name}, rawDesc );
    c#{sig.get_name[1..-1]}_set_descriptor( #{sig.get_name[1..-1]}Desc );
EOT
              print_BVT_branch_func( file, sig )
              file.print <<EOT
  }
EOT
            end
            signature_checker = 0
            break
          end
        }
      end
      }
  end

  def print_BVT_branch_func( file, signature ) #signatureの数だけ呼び出される
    str = ""
    paramSet = ""
    param = ""
    exp_val = ""
    flag = true # 初回のみtrue、以降はelse ifを使いたい
    # out引数のカウント
    int_count = 0
    double_count = 0
    char_count = 0

    signature.get_function_head_array.each{ |func|
      paramSet = ""
      exp_val = ""
      # 期待値のパラメータを取得する

      for target_function in 1..@test_case.length do
        if func.get_name.to_s == @test_case["target"+target_function.to_s]["function"] && @boundary_flag[target_function-1] == 1 then

          if func.get_return_type.get_type_str.include?("void") then
            exp_val = ""
          elsif func.get_return_type.get_type_str.include?("double") || func.get_return_type.get_type_str.include?("float") then
            exp_val = "exp_val->" + "data.mem_#{func.get_return_type.get_type_str.sub(/\*/, '_buf').sub('const ', '').sub('struct ', '').sub('32_t', '').sub('64_t', '')}"
          else
            exp_val = "exp_val->" + "data.mem_#{func.get_return_type.get_type_str.sub(/\*/, '_buf').sub('const ', '').sub('struct ', '')}"
          end

          int_count, double_count, char_count = 0, 0, 0
          n = func.get_paramlist.get_items.length
          func.get_paramlist.get_items.each_with_index { |paramDecl, idx|
            param = paramDecl.get_type.get_type_str # paramにはテストする関数の引数の型が入っている (例：int32_tなど)
            if param.include?("*") && !param.include?("const") then # paramが[out]指定子付きと判断
              if param.include?("int") || param.include?("INT") || param.include?("short") ||\
                 param.include?("SHORT") || param.include?("long") || param.include?("LONG") then
                paramSet.concat("(int *) ( VAR_data + sizeof(int)*#{int_count} + sizeof(double)*#{double_count} + sizeof(char)*#{char_count} )")
                int_count += 1
              elsif param.include?("double") || param.include?("float") then
                paramSet.concat("(double *) ( VAR_data + sizeof(int)*#{int_count} + sizeof(double)*#{double_count} + sizeof(char)*#{char_count} )")
                double_count += 1
              elsif param.include?("char") || param.include?("CHAR") then
                paramSet.concat("(char *) ( VAR_data + sizeof(int)*#{int_count} + sizeof(double)*#{double_count} + sizeof(char)*#{char_count} )")
                char_count += 1
              end
            # ここまで
            else #[in]指定子の場合
              if param.include?("struct") then
                paramSet.concat("&arguments[#{idx}].data.mem_#{param.sub(/\*/, '_buf').sub('const ', '').sub('struct ', '')}")
              else
                if param.include?("double") || param.include?("float") then
                  paramSet.concat("boundary[test_count] + boundary_count") # ここを編集した
                elsif param.include?("char") || param.include?("CHAR") then
                  paramSet.concat("arguments[#{idx}].data.mem_#{param.sub(/\*/, '_buf').sub('const ', '').sub('_t', '')}")
                else
#                 paramSet.concat("arguments[#{idx}].data.mem_#{param.sub(/\*/, '_buf').sub('const ', '')}")
                  paramSet.concat("boundary[test_count] + boundary_count") # ここを編集した
                end
              end
            end
            if idx + 1 < n then
              paramSet.concat(", ")
            end
          }
          print_BVT_call_desc( file, func.get_name.to_s, exp_val, signature, paramSet, int_count, double_count, char_count, flag )
          flag = false
        end
      end
    }
  end

  def print_BVT_call_desc( file, f_name, exp_val, signature, paramSet, int_count, double_count, char_count, flag )

    if flag then
      file.print <<EOT
      if( !strcmp( function_path, "#{f_name}") ){
        printf("\\nCall #{f_name}\\n");
EOT
    else
      file.print <<EOT
      else if( !strcmp( function_path, "#{f_name}") ){
        printf("\\nCall #{f_name}\\n");
EOT
    end

    if int_count + double_count + char_count > 0 then
      file.print <<EOT
        VAR_data = malloc( sizeof(int)*#{int_count} + sizeof(double)*#{double_count} + sizeof(char)*#{char_count} );
EOT
    end

    if exp_val == "" then
      file.print <<EOT
        c#{signature.get_name[1..-1]}_#{f_name}(  )}; /* この最後の括弧の中でテストする関数の引数を設定している */
        return 0;
EOT
    else
      file.print <<EOT
        for( int test_count = 0; test_count < 2; test_count++ ){
          for( int boundary_count = -1; boundary_count < 2; boundary_count++ ){
            printf("\\n[input  : %d]\\n", boundary[test_count] + boundary_count);
          /*  if( #{exp_val} == c#{signature.get_name[1..-1]}_#{f_name}( boundary[test_count] + boundary_count ) ){ */
            if( #{exp_val} == c#{signature.get_name[1..-1]}_#{f_name}( #{paramSet} ) ){
              printf("[Result : OK]\\n");
              result_count[count] = 1;
            }else{
              printf("[Result : NG]\\n");
              result_count[count] = 0;
            }
            count += 1;
          }
        }
        for( count = 0; count < 6; count++ ){
          if( result_count[count] == expect_result[count] ){
            if ( count == 5 ){
              printf("[ Expected result ]\\n");
              strcat(result_str, "| BV Test | #{signature.get_name[1..-1]}_#{f_name} | **passed ✓** |\\n");
            }
          } else {
            printf("[ Unexpected result ]\\n");
            strcat(result_str, "| BV Test | #{signature.get_name[1..-1]}_#{f_name} | **failed ✓** |\\n");
            break;
          }
        }
EOT
    end

    if int_count + double_count + char_count > 0 then
      file.print <<EOT
        free( VAR_data );
EOT
    end
    out_check( file, int_count, double_count, char_count )
    file.print <<EOT
      }
EOT
  end

  #
  # 同値分割テストを行うためのコードを生成
  #

  def print_equivalence_partitioning_test( file, namespace )
    file.print <<EOT
  CELLCB *p_cellcb;
  if (VALID_IDX(idx)) {
    p_cellcb = GET_CELLCB(idx);
  }
  else {
    /* エラー処理はここに記述します */
  } /* end if VALID_IDX(idx) */

  int i, j, k, tmp,  standard_val;
  int result_count[3] = { 0, 0, 0 };
  int expect_result[3] = { 0, 1, 0 }; 
  int EP_num = sizeof EP_boundary / sizeof EP_boundary[0];
  int EP_boundary_val[EP_num];
  int typical_val[EP_num+1];

  for( k = 0; k < EP_num; k++ ){
    EP_boundary_val[k] = EP_boundary[k];
  }

  if( EP_num != 1 ){ /* 複数の境界値を持てるように昇順にする */
    for( i = 0; i < EP_num-1; i ++ ){
      for( j = i+1; j < EP_num; j++ ){
        if( EP_boundary_val[i] > EP_boundary_val[j] ){
          tmp = EP_boundary_val[i];
          EP_boundary_val[i] = EP_boundary_val[j];
          EP_boundary_val[j] = tmp;
        }
      }
    } /* ここは一旦境界値二つの場合のみで考える */
    standard_val = ( EP_boundary_val[1] - EP_boundary_val[0] ) / 2;
    typical_val[0] = EP_boundary_val[0] - standard_val;
    typical_val[1] = ( EP_boundary_val[0] + EP_boundary_val[1] ) / 2;
    typical_val[2] = EP_boundary_val[1] + standard_val;
  } else {
    typical_val[0] = EP_boundary_val[0] - 50;
    typical_val[0] = EP_boundary_val[0] + 50;
  }

  printf("\\n--- Equivalence Partitioning Test ---\\n\\n");

  printf("input = [");
  for( k = 0; k < EP_num+1; k++ ){
    printf(" %d", typical_val[k]);
  }
  printf(" ]\\n");

  void *rawDesc;
EOT
    print_desc( file, Namespace.get_root )

    file.print <<EOT
  sprintf( VAR_cell_entry, "%s.%s", cell_path, entry_path );
  getRawEntryDescriptor( p_cellcb, VAR_cell_entry, &rawDesc, signature_path );
EOT
    print_EPT_branch_sig( file, Namespace.get_root )
  end

  def print_EPT_branch_sig( file, namespace )
    flag = true
    func = ""
    signature_checker = 0
    namespace.travers_all_signature{ |sig|
      if  sig.get_namespace_path.to_s =~ /nTECSInfo::/ || \
          sig.get_namespace_path.to_s =~ /::s.*Task.*/ || \
          sig.get_namespace_path.to_s =~ /::sAccessor/ || \
          sig.get_namespace_path.to_s =~ /::sTECSUnit/ || \
          sig.get_namespace_path.to_s =~ /::sJSMN/ || \
          sig.get_namespace_path.to_s =~ /::s.*Kernel/ || \
          sig.get_namespace_path.to_s =~ /::s.*Semaphore/ || \
          sig.get_namespace_path.to_s =~ /::s.*Eventflag/ || \
          sig.get_namespace_path.to_s =~ /::s.*Dataqueue/ || \
          sig.get_namespace_path.to_s =~ /::sInitialize.*/ || \
          sig.get_namespace_path.to_s =~ /::s.*VM/ || \
          sig.get_namespace_path.to_s =~ /::sMain/ || \
          sig.get_namespace_path.to_s =~ /::s.*Alarm/ || \
          sig.get_namespace_path.to_s =~ /::sFixedSizeMemoryPool/ || \
          sig.get_namespace_path.to_s =~ /::sMessageBuffer/ || \
          sig.get_namespace_path.to_s =~ /::sTerminateRoutineBody/ || \
          sig.get_namespace_path.to_s =~ /::s.*HandlerBody/ || \
          sig.get_namespace_path.to_s =~ /::sConfigInterrupt/ || \
          sig.get_namespace_path.to_s =~ /::sCyclic/ || \
          sig.get_namespace_path.to_s =~ /::sMalloc/ then
      else

        sig.get_function_head_array.each{ |func|
          for i in 1..@test_case.length do
            if func.get_name.to_s == @test_case["target"+i.to_s]["function"] then
              signature_checker = 1
              break
            end
          end

          if signature_checker == 1 then
            if flag then
              flag = false
              file.print <<EOT
  if( !strcmp(signature_path, "#{sig.get_name}" ) ){
    setRawEntryDescriptor( #{sig.get_name[1..-1]}Desc, #{sig.get_name}, rawDesc );
    c#{sig.get_name[1..-1]}_set_descriptor( #{sig.get_name[1..-1]}Desc );
EOT
              print_EPT_branch_func( file, sig )
              file.print <<EOT
  }
EOT
            else
              file.print <<EOT
  else if( !strcmp(signature_path, "#{sig.getname}" ) ){
    setRawEntryDescriptor( #{sig.get_name[1..-1]}Desc, #{sig.get_name}, rawDesc );
    c#{sig.get_name[1..-1]}_set_descriptor( #{sig.get_name[1..-1]}Desc );
EOT
              print_EPT_branch_func( file, sig )
              file.print <<EOT
  }
EOT
            end
            signature_checker = 0
            break
          end
        }
      end
    }
  end

  def print_EPT_branch_func( file, signature )
    str = ""
    paramSet = ""
    param = ""
    exp_val = ""
    flag = true
    # out引数のカウント
    int_count = 0
    double_count = 0
    char_count = 0

    signature.get_function_head_array.each{ |func|
      paramSet = ""
      exp_val = ""

      for target_function in 1..@test_case.length do
        if func.get_name.to_s == @test_case["target"+target_function.to_s]["function"] && @EP_flag[target_function-1] == 1 then

          if func.get_return_type.get_type_str.include?("void") then
            exp_val = ""
          elsif func.get_return_type.get_type_str.include?("double") || func.get_return_type.get_type_str.include?("float") then
            exp_val = "exp_val->" + "data.mem_#{func.get_return_type.get_type_str.sub(/\*/, '_buf').sub('const ', '').sub('struct ', '').sub('32_t', '').sub('64_t', '')}"
          else
            exp_val = "exp_val->" + "data.mem_#{func.get_return_type.get_type_str.sub(/\*/, '_buf').sub('const ', '').sub('struct ', '')}"
          end

          int_count, double_count, char_count = 0, 0, 0
          n = func.get_paramlist.get_items.length
          func.get_paramlist.get_items.each_with_index { |paramDecl, idx|
            param = paramDecl.get_type.get_type_str
            if param.include?("*") && !param.include?("const") then
              if param.include?("int") || param.include?("INT") || param.include?("short") ||\
                 param.include?("SHORT") || param.include?("long") || param.include?("LONG") then
                paramSet.concat("(int *) ( VAR_data + sizeof(int)*#{int_count} + sizeof(double)*#{double_count} + sizeof(char)*#{char_count} )")
                int_count += 1
              elsif param.include?("double") || param.include?("float") then
                paramSet.concat("(double *) ( VAR_data + sizeof(int)*#{int_count} + sizeof(double)*#{double_count} + sizeof(char)*#{char_count} )")
                double_count += 1
              elsif param.include?("char") || param.include?("CHAR") then
                paramSet.concat("(char *) ( VAR_data + sizeof(int)*#{int_count} + sizeof(double)*#{double_count} + sizeof(char)*#{char_count} )")
                char_count += 1
              end
            else
              if param.include?("struct") then
                paramSet.concat("&arguments[#{idx}].data.mem_#{param.sub(/\*/, '_buf').sub('const ', '').sub('struct ', '')}")
              else
                if param.include?("double") || param.include?("float") then
                  paramSet.concat("typical_val[test_count]") # ここを編集する必要あり
                elsif param.include?("char") || param.include?("CHAR") then
                  paramSet.concat("arguments[#{idx}].data.mem_#{param.sub(/\*/, '_buf').sub('const ', '').sub('_t', '')}")
                else
#                 paramSet.concat("arguments[#{idx}].data.mem_#{param.sub(/\*/, '_buf').sub('const ', '')}")
                  paramSet.concat("typical_val[test_count]") # ここを編集する必要あり
                end
              end
            end
            if idx + 1 < n then
              paramSet.concat(", ")
            end
          }
          print_EPT_call_desc( file, func.get_name.to_s, exp_val, signature, paramSet, int_count, double_count, char_count, flag )
          flag = false
        end
      end
    }
  end

  def print_EPT_call_desc( file, f_name, exp_val, signature, paramSet, int_count,double_count, char_count, flag )
    if flag then
      file.print <<EOT
      if( !strcmp(function_path, "#{f_name}") ){
        printf("\\nCall #{f_name}\\n");
EOT
    else
      file.print <<EOT
      else if( !strcmp( function_path, "#{f_name}") ){
        printf("\\nCall #{f_name}\\n");
EOT
    end

    if int_count + double_count + char_count > 0 then
      file.print <<EOT
        VAR_data = malloc( sizeof(int)*#{int_count} + sizeof(double)*#{double_count} + sizeof(char)*#{char_count} );
EOT
    end

    if exp_val == "" then
      file.print <<EOT
        c#{signature.get_name[1..-1]}_#{f_name}( #{paramSet} )};
        return 0;
EOT
    else
      file.print <<EOT
        for( int test_count = 0; test_count < EP_num+1; test_count++ ){
          printf("\\n[input  : %d]\\n", typical_val[test_count]);
          if( #{exp_val} == c#{signature.get_name[1..-1]}_#{f_name}( #{paramSet} ) ){
            printf("[Result : OK]\\n");
            result_count[test_count] = 1;
          } else {
            printf("[Result : NG]\\n");
            result_count[test_count] = 0;
          }
        }
        for( int test_count = 0; test_count < EP_num+1; test_count++ ){
          if( result_count[test_count] == expect_result[test_count] ){
            if( test_count == EP_num ){
              printf("[ Expected result ]\\n");
              strcat(result_str, "| EP Test | #{signature.get_name[1..-1]}_#{f_name} | **passed ✓** |\\n");
            }
          } else {
            printf("[ Unexpected result ]\\n");
            strcat(result_str, "| EP Test | #{signature.get_name[1..-1]}_#{f_name} | **failed ✓** |\\n");
            break;
          }
        }
EOT
    end

    if int_count + double_count + char_count > 0 then
      file.print <<EOT
        free( VAR_data );
EOT
    end
    out_check( file, int_count, double_count, char_count )
    file.print <<EOT
      }
EOT
  end

end
