# -*- coding: utf-8 -*-
#
#  TECS Generator
#      Generator for TOPPERS Embedded Component System
#
#   Copyright (C) 2008-2017 by TOPPERS Project
#--
#   上記著作権者は，以下の(1)〜(4)の条件を満たす場合に限り，本ソフトウェ
#   ア（本ソフトウェアを改変したものを含む．以下同じ）を使用・複製・改
#   変・再配布（以下，利用と呼ぶ）することを無償で許諾する．
#   (1) 本ソフトウェアをソースコードの形で利用する場合には，上記の著作
#       権表示，この利用条件および下記の無保証規定が，そのままの形でソー
#       スコード中に含まれていること．
#   (2) 本ソフトウェアを，ライブラリ形式など，他のソフトウェア開発に使
#       用できる形で再配布する場合には，再配布に伴うドキュメント（利用
#       者マニュアルなど）に，上記の著作権表示，この利用条件および下記
#       の無保証規定を掲載すること．
#   (3) 本ソフトウェアを，機器に組み込むなど，他のソフトウェア開発に使
#       用できない形で再配布する場合には，次のいずれかの条件を満たすこ
#       と．
#     (a) 再配布に伴うドキュメント（利用者マニュアルなど）に，上記の著
#         作権表示，この利用条件および下記の無保証規定を掲載すること．
#     (b) 再配布の形態を，別に定める方法によって，TOPPERSプロジェクトに
#         報告すること．
#   (4) 本ソフトウェアの利用により直接的または間接的に生じるいかなる損
#       害からも，上記著作権者およびTOPPERSプロジェクトを免責すること．
#       また，本ソフトウェアのユーザまたはエンドユーザからのいかなる理
#       由に基づく請求からも，上記著作権者およびTOPPERSプロジェクトを
#       免責すること．
#
#   本ソフトウェアは，無保証で提供されているものである．上記著作権者お
#   よびTOPPERSプロジェクトは，本ソフトウェアに関して，特定の使用目的
#   に対する適合性も含めて，いかなる保証も行わない．また，本ソフトウェ
#   アの利用により直接的または間接的に生じたいかなる損害に関しても，そ
#   の責任を負わない．
#
#   $Id: MrubyBridgeCellPlugin.rb 3072 2019-05-02 23:47:42Z okuma-top $
#++

#== celltype プラグインの共通の親クラス
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

#########################################################################################
  #===  受け口関数の本体コードを生成（頭部と末尾は別途出力）
  #ct_name:: Symbol    (プラグインで生成された) セルタイプ名 ．Symbol として送られてくる
  def gen_ep_func_body( file, b_singleton, ct_name, global_ct_name, sig_name, ep_name, func_name, func_global_name, func_type, paramSet )
    # tTECSUnit の受け口関数のセルタイプコード (C言語) を生成する
    file.print <<EOT
  CELLCB  *p_cellcb;
  if (VALID_IDX(idx)) {
    p_cellcb = GET_CELLCB(idx);
  }
  else {
    /* エラー処理コードをここに記述します */
  } /* end if VALID_IDX(idx) */
  puts("");
  printf( "--- TECSUnit ---" );
  puts("");
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

  def print_branch_func( file, signature )
    str = ""
    paramSet = ""
    param = ""
    exp_val = ""
    flag = true # 初回のみtrue以降はelse ifを使いたい。
    # out引数のカウント
    int_count = 0
    double_count = 0
    char_count = 0

    signature.get_function_head_array.each{ |func|
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
      n = func.get_paramlist.get_items.length
      func.get_paramlist.get_items.each_with_index { |paramDecl, idx|
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
        printf("Call #{f_name}");
        puts("");
EOT
    else
      file.print <<EOT
      else if( !strcmp( function_path, "#{f_name}" ) ){
        printf("Call #{f_name}");
        puts("");
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
            puts("");
            printf("Result：OK");
            puts("");
        }else{
/*            return -1; */
            puts("");
            printf("Result：NG");
            puts("");
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
end

