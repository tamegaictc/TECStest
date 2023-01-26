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
class JSMNPlugin < CellPlugin

  # プラグイン引数名 => Proc
  # @@cell_list = {}      # gen_cdl_file'ed list to avoid duplicate generation
  # @@signature_list = {}

  #=== CellPlugin# initialize
  #cell::     Cell        セル（インスタンス）
  # このメソッドは、セルの構文解析が終わったところで呼び出される
  # この段階では意味解析が終わっていない
  def initialize( cell, option )
    dbgPrint "  #{self.class.name}: initialzie=#{cell.get_name} option=#{option}\n"
    super
    @cell = cell

    @plugin_arg_str = CDLString.remove_dquote option
    # @plugin_arg_str = option.gsub( /\A"(.*)/, '\1' )    # 前後の "" を取り除く
    # @plugin_arg_str.sub!( /(.*)"\z/, '\1' )
    @plugin_arg_list = {}
  end

  def gen_cdl_file file # celltype"tJSMN"を定義。プラグインでやる必要はない
    file.print <<EOT
celltype tJSMN {
  entry sJSMN eJSMN;

  attr {
    int16_t LEN = 1024; // jsonをまるごと読み込んだ時のサイズ
    int16_t TMP_LEN = 128; // argの値を一時的に格納
  /* json keywords：変更する場合はここを変える */
    char_t *key_region = "region";
    char_t *key_cell = "cell";
    char_t *key_entry = "entry";
    char_t *key_function = "function";
    char_t *key_arg = "argument";
    char_t *key_exp = "exp_val";
    char_t *key_pre_cond = "pre_cond";
    char_t *key_post_cond = "post_cond";
    char_t *key_boundary = "boundary_val";
    char_t *key_EP_boundary = "EP_boundary_val";
  };
  var {
    [size_is(LEN)]
      char_t  *json_str;
    [size_is(TMP_LEN)]
      char_t  *tmp_str;
    [size_is(TMP_LEN)]
      char_t  *target_path;

    int counter = 0; // targetの数を数える
    int BVT_counter = 0;
    int EPT_counter = 0;
  };
};
EOT
  end

#########################################################################################
  #===  受け口関数の本体コードを生成（頭部と末尾は別途出力）
  #ct_name:: Symbol    (プラグインで生成された) セルタイプ名 ．Symbol として送られてくる
  def gen_ep_func_body( file, b_singleton, ct_name, global_ct_name, sig_name, ep_name, func_name, func_global_name, func_type, paramSet )
    # tJSMN の受け口関数のセルタイプコード (C言語) を生成する以下の４つの関数

    @test_case = ""
    @boundary_flag = []
    @EP_flag = []
    test_method_flag = 0

    if func_name.to_s == "json_open" then
        print_json_open( file, Namespace.get_root )
    end
    if func_name.to_s == "json_parse_path" then
        print_parse_path( file, Namespace.get_root )
    end
    if func_name.to_s == "json_parse_arg" then
        print_parse_arg( file, Namespace.get_root )
    end
    if func_name.to_s == "json_parse_cond" then
        print_parse_cond( file, Namespace.get_root )
    end
    if func_name.to_s == "json_parse_boundary" then
        test_method_flag = 1
        parse_json( file, Namespace.get_root, test_method_flag )
        if @boundary_flag.find { |number| number == 1} == 1 then
            print_parse_boundary( file, Namespace.get_root )
        end
    end
    if func_name.to_s == "json_parse_EP_boundary" then
        test_method_flag = 2
        parse_json( file, Namespace.get_root, test_method_flag )
        if @EP_flag.find { |number| number == 1} == 1 then
            print_parse_EP_boundary( file, Namespace.get_root )
        end
    end
  end

  def parse_json( file, namespace, flag )
    require 'json'
    file = File.open("target.json")
    @test_case = JSON.load(file)

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

# entry function : json_open の出力
  def print_json_open( file, namespace )
    file.print <<EOT
  CELLCB  *p_cellcb;
  if (VALID_IDX(idx)) {
    p_cellcb = GET_CELLCB(idx);
  }
  else {
    /* エラー処理コードをここに記述します */
  } /* end if VALID_IDX(idx) */

  /* ここに処理本体を記述します #_TEFB_# */
    char str_tmp[N];
    int co_flag = 0, co_start, i, j;
    FILE *fp;

    if( ( fp = fopen("target.json", "r") ) == NULL ) {
        printf( "Failed to open" );
        return -1;
    }
    while( fgets( str_tmp , N, fp ) != NULL ) {
        co_start = 0;
        for( i = 0; i < N -1; i++ ){
            if( str_tmp[i] == '/' && str_tmp[i+1] == '/' && !co_flag ){
                str_tmp[i] = '\\0';
                break;
            }
            if( str_tmp[i] == '/' && str_tmp[i+1] == '*' && !co_flag ){
                co_start = i;
                co_flag = 1;
            }
            if( str_tmp[i] == '*' && str_tmp[i+1] == '/' && co_flag ){
                for(j = 0; str_tmp[(i+2)+j] != '\\0'; j++ ){
                    str_tmp[co_start + j] = str_tmp[(i+2)+j];
                }
                str_tmp[co_start + j] = '\\0';
                i = co_start;
                co_flag = 0;
            }
        }
        if( co_flag && co_start > 0 ){
            str_tmp[co_start] = '\\0';
            strcat( VAR_json_str, str_tmp );
        }
        if( str_tmp[0] != '\\0' && str_tmp[0] != '\\n' && !co_flag ){
            strcat( VAR_json_str, str_tmp );
        }
    }
    fclose( fp );
    return 0;
EOT
  end

# entry function : json_parse_path の出力
  def print_parse_path( file, namespace )
    file.print <<EOT
ER    ercd = E_OK;
  CELLCB  *p_cellcb;
  if (VALID_IDX(idx)) {
    p_cellcb = GET_CELLCB(idx);
  }
  else {
    return(E_ID);
  } /* end if VALID_IDX(idx) */

  /* ここに処理本体を記述します #_TEFB_# */
    int r, i, j, k, l, m, array_size, arg_size, EP_size;
    jsmn_parser p;
    jsmntok_t t[128]; /* We expect no more than 128 tokens */
    char target_path[10];
    char str_tmp[8];

    sprintf( target_path, "target%d", target_num );

    jsmn_init(&p); /* pには現在パースされている文字列と、その文字列内の現在の位置が格納されている→それを初期化 */
    r = jsmn_parse( &p, VAR_json_str, strlen(VAR_json_str), t, sizeof(t)/sizeof(t[0]) );
    if(r < 0){
        printf( "Failed to parse JSON: %d", r );
        return -1;
    }
  /* Assume the top-level element is an object */
    if( r < 1 || t[0].type != JSMN_OBJECT ){
        printf( "Object expectd" );
        return -1;
    }

  /* Loop over all keys of the root object */
    for( l = 1; l < r; l++ ){
        if( jsoneq( VAR_json_str, &t[l], target_path ) == 0 ){
            if( t[l+1].type != JSMN_OBJECT ){
                printf("Object expected for target");
                return -1;
            }
            i = l + 2;
            for( k = 0; k < t[l+1].size; k++ ){
                if( jsoneq( VAR_json_str, &t[i], ATTR_key_cell ) == 0 ){
                    strcpy_n( c_path, t[i+1].end-t[i+1].start, VAR_json_str + t[i+1].start );
                    i += 2;
                }else if( jsoneq( VAR_json_str, &t[i], ATTR_key_entry ) == 0 ){
                    strcpy_n( e_path, t[i+1].end-t[i+1].start, VAR_json_str + t[i+1].start );
                    i += 2;
                }else if( jsoneq( VAR_json_str, &t[i], ATTR_key_function ) == 0 ){
                    strcpy_n( f_path, t[i+1].end-t[i+1].start, VAR_json_str + t[i+1].start );
                    i += 2;
                }else if( jsoneq( VAR_json_str, &t[i], ATTR_key_arg ) == 0 ) {
                    i += 1;
                    arg_size = t[i].size;
                    for( j = 0; j < arg_size; j++ ){
                        i += 1; // iは各要素を指す
                        if( t[i].type == JSMN_ARRAY ){
                            array_size =  t[i].size;
                            for( m = 0; m < array_size; m++ ){
                                i += 1; // 配列の中身に注目
                                if( t[i].size > 1 ){
                                  i += t[i].size;
                                }
                            }
                        }
                        if( t[i].type == JSMN_OBJECT ){
                            array_size =  t[i].size;
                            for( m = 0; m < array_size; m++){
                                i += 2; // member
                                if( t[i].size > 1 ){
                                  i += t[i].size;
                                }
                            }
                        }
                    }
                    i += 1; // 最後には配列を抜ける
                }else if( jsoneq( VAR_json_str, &t[i], ATTR_key_boundary ) == 0 || jsoneq( VAR_json_str, &t[i], ATTR_key_EP_boundary) == 0 ){
                    if( jsoneq( VAR_json_str, &t[i], ATTR_key_boundary ) == 0 ){
                        i += 1;
                        if( t[i].type == JSMN_ARRAY ){
                          i += t[i].size;
                        } else {
                          printf("ERROR: boundary_val\\n");
                          return -1;
                        }
                        i += 1; /* 配列を抜ける */
                    }else if( jsoneq( VAR_json_str, &t[i], ATTR_key_EP_boundary ) == 0 ){
                        i += 1;
                        if( t[i].type == JSMN_ARRAY ){
                          i += t[i].size;
                        } else {
                          printf("ERROR: EP_boundary_val\\n");
                          return -1;
                        }
                        i += 1;
                    }
                }else if( jsoneq( VAR_json_str, &t[i], ATTR_key_exp ) == 0 ){
                    i += 2; /* ignore */
                } else {
                    printf( "Unexpected key: %.*s\\n", t[i].end-t[i].start, VAR_json_str + t[i].start );
                    return -1;
                }
            }
            return 0;
        }
    }
    return 1;
EOT
  end

# entry function : json_parse_arg の出力
  def print_parse_arg( file, namespace )
    char_list = []

    struct_list = [] # 構造体名
    struct_mem = [] # 構造体のメンバ(tmp)
    struct_mem_type = [] # 構造体のメンバのタイプ(tmp)
    struct_mem_list = [] # 構造体メンバのリスト
    struct_mem_type_list = [] # 構造体メンバのタイプリスト

    arr_list = []
    out_list = []
    num_list = []

    ret_type_list = []

    namespace.travers_all_signature{ |sig|
      # ignnore these signatures (テスト対象外とみなします)
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
        sig.each_param{ |decl, paramDecl| # decl:関数, paramDecl:関数の各引数
          # 引数の設定
          param = paramDecl.get_type.get_type_str
          if param.include?("*") then
            if param.include?("const") then
              if param.include?("char") || param.include?("CHAR") then # [in]: char*型
                if !char_list.include?(param) then
                  char_list << param
                end
              elsif param.include?("struct") then # [in]: struct*型
                paramDecl.get_type.get_type.get_members_decl.get_items.each { |decl|
                  struct_mem << decl.get_name.to_s
                  struct_mem_type << decl.get_type.get_type_str
                }
                struct_mem_list << struct_mem
                struct_mem_type_list << struct_mem_type
                struct_mem = [] # リセット
                struct_mem_type = [] # リセット
                if !struct_list.include?(param) then
                  struct_list << param
                end
              else
                if !arr_list.include?(param) then # [in]: num*, typedef*型
                  arr_list << param
                end
              end
            else
              if !out_list.include?(param) then # [out]: 型
                out_list << param
              end
            end
          else
            if !num_list.include?(param) then # [in]: num型,typedef型
              num_list << param
            end
          end
          # 返り値の設定
          ret_type = decl.get_type.get_type_str # ポインタ型は無視
          if !ret_type.include?("*") && !ret_type_list.include?(ret_type) then
            ret_type_list << decl.get_type.get_type_str
          end
        }
      end
    }

    # 出力開始
    file.print <<EOT
  ER ercd = E_OK;
  CELLCB  *p_cellcb;
  if (VALID_IDX(idx)) {
    p_cellcb = GET_CELLCB(idx);
  }
  else {
    return(E_ID);
  } /* end if VALID_IDX(idx) */

  /* ここに処理本体を記述します #_TEFB_# */
    int r, i, j, k, l, m, arg_size, array_size;
    jsmn_parser p;
    jsmntok_t t[128]; /* We expect no more than 128 tokens */
    char target_path[10];

    sprintf( target_path, "target%d", target_num );

    jsmn_init(&p);
    r = jsmn_parse( &p, VAR_json_str, strlen(VAR_json_str), t, sizeof(t)/sizeof(t[0]) );
    if(r < 0){
        printf( "Failed to parse JSON: %d", r );
        return -1;
    }
  /* Assume the top-level element is an object */
    if( r < 1 || t[0].type != JSMN_OBJECT ){
        printf( "Object expected" );
        return -1;
    }

  /* Loop over all keys of the root object */
    for( l = 1; l < r; l++ ){
        if( jsoneq( VAR_json_str, &t[l], target_path ) == 0 ){
            if( t[l+1].type != JSMN_OBJECT ){
                printf("Object expected for target");
                return -1;
            }
            i = l + 2;
            for( k = 0; k < t[l+1].size; k++ ){
                if( jsoneq( VAR_json_str, &t[i], ATTR_key_cell ) == 0 ){
                    i += 2; /* ignore */
                }else if( jsoneq( VAR_json_str, &t[i], ATTR_key_entry ) == 0 ){
                    i += 2; /* ignore */
                }else if( jsoneq( VAR_json_str, &t[i], ATTR_key_function ) == 0 ){
                    i += 2; /* ignore */
                }else if( jsoneq( VAR_json_str, &t[i], ATTR_key_arg ) == 0 ) {
                    if(t[i+1].type != JSMN_ARRAY){
                        continue; /* We expect groups to be an array of strings */
                    }
                    i += 1;
                    arg_size = t[i].size;
                    *arg_num = arg_size; // 引数の数をTaskMainに渡す
                    for( j = 0; j < arg_size; j++ ){
                        i += 1; // iは各要素を指す
                        if( t[i].type == JSMN_OBJECT ){
                            if( strstr( arguments[j].type, "const struct" ) == NULL ){
                              printf("Arg %d is not struct type", j+1 );
                              return -1;
                            }
                            array_size =  t[i].size;
                            for( m = 0; m < array_size; m++ ){
                                i += 1; // objの中身Tag名に注目
                                strcpy_n( VAR_tmp_str, t[i].end - t[i].start, VAR_json_str + t[i].start );
EOT
    # 1.構造体リストの出力
    print_struct_list( file, struct_list, struct_mem_list, struct_mem_type_list )
    file.print <<EOT
                            }
                        }else if( t[i].type == JSMN_ARRAY ){
                            array_size =  t[i].size;
                            for( m = 0; m < array_size; m++ ){
                                i += 1; // 配列の中身に注目
                                strcpy_n( VAR_tmp_str, t[i].end - t[i].start, VAR_json_str + t[i].start );
EOT
    # 2.配列リストの出力
    print_arr_list( file, arr_list )
    file.print <<EOT
                            }
                        }else if( t[i].type == JSMN_STRING ){
EOT
    # 3.文字列リストの出力
    print_char_list( file, char_list )
    file.print <<EOT
                        }else if( t[i].type == JSMN_PRIMITIVE ){
                            strcpy_n( VAR_tmp_str, t[i].end - t[i].start, VAR_json_str + t[i].start );
EOT
    # 4.primitiveリストの出力
    print_num_list( file, num_list )
    file.print <<EOT
                        }else if( t[i].type == JSMN_UNDEFINED ){
                            printf( "Unexpected value: %.*s", t[i].end - t[i].start, VAR_json_str + t[i].start );
                        }else{
                            printf( "Wrong Type: %.*s", t[i].end - t[i].start, VAR_json_str + t[i].start );
                        }
                    }
                    i += 1; // 最後には配列を抜ける
                }else if( jsoneq( VAR_json_str, &t[i], ATTR_key_boundary) == 0 || jsoneq( VAR_json_str, &t[i], ATTR_key_EP_boundary ) == 0 ){
                    if( jsoneq( VAR_json_str, &t[i], ATTR_key_boundary ) == 0 ){
                        i += 1;
                        if( t[i].type == JSMN_ARRAY ){
                          i += t[i].size;
                        } else {
                          printf("ERROR: boundary_val\\n");
                          return -1;
                        }
                        i += 1; /* 配列を抜ける */
                    }else if( jsoneq( VAR_json_str, &t[i], ATTR_key_EP_boundary ) == 0 ){
                        i += 1;
                        if( t[i].type == JSMN_ARRAY ){
                          i += t[i].size;
                        } else {
                          printf("ERROR: EP_boundary_val\\n");
                          return -1;
                        }
                        i += 1;
                    }
                /* 期待値 */
                }else if( jsoneq( VAR_json_str, &t[i], ATTR_key_exp ) == 0 ){
                    if( t[i+1].type == JSMN_ARRAY ){
                        printf("Return type is not support 'char' ", j+1 );
                        return -1;
                    }else if( t[i+1].type == JSMN_STRING ){
                        printf("Return type is not support 'char' ", j+1 );
                        return -1;
                    }else if( t[i+1].type == JSMN_PRIMITIVE ){
                        strcpy_n( VAR_tmp_str, t[i+1].end - t[i+1].start, VAR_json_str + t[i+1].start );
EOT
    # 5.返り値リストの出力
    print_ret_type_list( file, ret_type_list )
    file.print <<EOT
                    }else if( t[i+1].type == JSMN_UNDEFINED ){
                        printf( "Unexpected value: %.*s", t[i+1].end - t[i+1].start, VAR_json_str + t[i+1].start );
                    }else{
                        printf( "Wrong Type: %.*s", t[i+1].end - t[i+1].start, VAR_json_str + t[i+1].start );
                    }
                    i += 2;
                } else {
                    printf( "Unexpected key: %.*s", t[i].end-t[i].start, VAR_json_str + t[i].start );
                    return -1;
                }
            }
            VAR_counter += 1;
            if( VAR_counter >= t[0].size ){
                return 2;
            }
            return 0;
        }
    }
    return 1;
EOT
  end

  # 1.構造体リストの出力
  def print_struct_list( file, struct_list, struct_mem_list, struct_mem_type_list )
    struct_list.each_with_index{ |obj, idx|
      if idx == 0 then
        file.print <<EOT
                                if( !strcmp(arguments[j].type,"#{obj}") ){
EOT
      else
        file.print <<EOT
                                else if( !strcmp(arguments[j].type,"#{obj}") ){
EOT
      end
      struct_mem_list[idx].each_with_index{ |mem, idx2|
        if idx2 == 0 then
          file.print <<EOT
                                    if( !strcmp( VAR_tmp_str, "#{mem}" ) ){
                                        i += 1;
EOT
        else
          file.print <<EOT
                                    }else if( !strcmp( VAR_tmp_str, "#{mem}" ) ){
                                        i += 1;
EOT
        end

        if struct_mem_type_list[idx][idx2].include?("char")  || struct_mem_type_list[idx][idx2].include?("CHAR") then
          file.print <<EOT
                                        strcpy_n( arguments[j].data.mem_#{obj.sub(/\*/, '_buf').sub('const ', '').sub('struct ', '')}.#{mem}, t[i].end - t[i].start, VAR_json_str + t[i].start );
EOT
        elsif struct_mem_type_list[idx][idx2].include?("const") && struct_mem_type_list[idx][idx2].include?("*") then
          file.print <<EOT
                                        /* Not support Array type in struct */
                                        return -1;
EOT
        elsif struct_mem_type_list[idx][idx2].include?("double") || struct_mem_type_list[idx][idx2].include?("float") then
          file.print <<EOT
                                        strcpy_n( VAR_tmp_str, t[i].end - t[i].start, VAR_json_str + t[i].start );
                                        arguments[j].data.mem_#{obj.sub(/\*/, '_buf').sub('const ', '').sub('struct ', '').sub('32_t', '').sub('64_t', '')}.#{mem} = atof( VAR_tmp_str );
EOT
        else
          file.print <<EOT
                                        strcpy_n( VAR_tmp_str, t[i].end - t[i].start, VAR_json_str + t[i].start );
                                        arguments[j].data.mem_#{obj.sub(/\*/, '_buf').sub('const ', '').sub('struct ', '').sub('32_t', '').sub('64_t', '')}.#{mem} = atoi( VAR_tmp_str );
EOT
        end
      }
        file.print <<EOT
                                    }else{
                                       /* Cannot found */
                                       return -1;
                                    }
                                }else{
                                  /* Cannot found */
                                  return -1;
                                }
EOT

    }
  end

  # 2.配列リストの出力
  def print_arr_list( file, arr_list )
    arr_list.each_with_index { |obj, idx|
      if obj.include?("void") then
        if idx == 0 then
          file.print <<EOT
                                if( !strcmp(arguments[j].type,"#{obj}") ){
                                  /* ignore */
EOT
        else
          file.print <<EOT
                                }else if( !strcmp(arguments[j].type,"#{obj}") ){
                                  /* ignore */
EOT
        end
      elsif obj.include?("double") || obj.include?("float") then
        if idx == 0 then
          file.print <<EOT
                                if( !strcmp(arguments[j].type,"#{obj}") ){
                                    arguments[j].data.mem_#{obj.sub(/\*/, '_buf').sub('const ', '').sub('32_t', '').sub('64_t', '')}[m] = atof( VAR_tmp_str );
EOT
        else
          file.print <<EOT
                                }else if( !strcmp(arguments[j].type,"#{obj}") ){
                                    arguments[j].data.mem_#{obj.sub(/\*/, '_buf').sub('const ', '').sub('32_t', '').sub('64_t', '')}[m] = atof( VAR_tmp_str );
EOT
        end
      else
        if idx == 0 then
          file.print <<EOT
                                if( !strcmp(arguments[j].type,"#{obj}") ){
                                    arguments[j].data.mem_#{obj.sub(/\*/, '_buf').sub('const ', '')}[m] = atoi( VAR_tmp_str );
EOT
        else
          file.print <<EOT
                                }else if( !strcmp(arguments[j].type,"#{obj}") ){
                                    arguments[j].data.mem_#{obj.sub(/\*/, '_buf').sub('const ', '')}[m] = atoi( VAR_tmp_str );
EOT
        end
      end
    }
    if !arr_list.empty? then
      file.print <<EOT
                                }else{
                                    /* Arg %d is not array type */
                                    return -1;
                                }
EOT
    end
  end

  # 3.文字列リストの出力
  def print_char_list( file, char_list )
    if !char_list.empty? then
        file.print <<EOT
                            strcpy_n( VAR_tmp_str, t[i].end - t[i].start, VAR_json_str + t[i].start );
                            if( !strcmp(VAR_tmp_str, "[out]") ){
                                if( strstr(arguments[j].type,"const") != NULL ){
                                    printf("Arg %d is not out arguments\\n", j+1 );
                                    return -1;
                                }
EOT
        char_list.each{ |obj|
          if obj.include?("**") then
            file.print <<EOT
                            }else if( !strcmp(arguments[j].type,"#{obj}") ){
                              /* ignore */
EOT
          else
            file.print <<EOT
                            }else if( !strcmp(arguments[j].type,"#{obj}") ){
                                strcpy_n( arguments[j].data.mem_#{obj.sub(/\*/, '_buf').sub('const ', '').sub('_t', '')}, t[i].end - t[i].start, VAR_json_str + t[i].start );
EOT
          end
        }
        file.print <<EOT
                            }else{
                                /* Arg is not char type */
                                return -1;
                            }
EOT
    end
  end

  # 4.primitiveリストの出力
  def print_num_list( file, num_list )
    num_list.each_with_index{ |obj, idx|
      if obj.include?("double") || obj.include?("float") then
        if idx == 0 then
          file.print <<EOT
                            if( !strcmp(arguments[j].type,"#{obj}") ){
                                arguments[j].data.mem_#{obj.sub('32_t', '').sub('64_t', '')} = atof( VAR_tmp_str );
EOT
        else
          file.print <<EOT
                            }else if( !strcmp(arguments[j].type,"#{obj}") ){
                                arguments[j].data.mem_#{obj.sub('32_t', '').sub('64_t', '')} = atof( VAR_tmp_str );
EOT
        end
      else
        if idx == 0 then
          file.print <<EOT
                            if( !strcmp(arguments[j].type,"#{obj}") ){
                                arguments[j].data.mem_#{obj} = atoi( VAR_tmp_str );
EOT
        else
          file.print <<EOT
                            }else if( !strcmp(arguments[j].type,"#{obj}") ){
                                arguments[j].data.mem_#{obj} = atoi( VAR_tmp_str );
EOT
        end
      end
    }
    if !num_list.empty? then
      file.print <<EOT
                            }else{
                                printf("Arg %d is not numeric type", j+1 );
                                return -1;
                            }
EOT
    end
  end

  # 5.返り値リストの出力
  def print_ret_type_list( file, ret_type_list )
    ret_type_list.each_with_index{ |obj, idx|
      if obj.include?("void") then
        if idx == 0 then
          file.print <<EOT
                        if( !strcmp( exp_val->type, "#{obj}") ){
                          /* ignore */
EOT
        else
          file.print <<EOT
                        }else if( !strcmp( exp_val->type, "#{obj}") ){
                          /* ignore */
EOT
        end

      elsif obj.include?("double") || obj.include?("float") then
        if idx == 0 then
          file.print <<EOT
                        if( !strcmp( exp_val->type, "#{obj}") ){
                            exp_val->data.mem_#{obj.sub('32_t', '').sub('64_t', '')} = atof( VAR_tmp_str );
EOT
        else
          file.print <<EOT
                        }else if( !strcmp( exp_val->type, "#{obj}") ){
                            exp_val->data.mem_#{obj.sub('32_t', '').sub('64_t', '')} = atof( VAR_tmp_str );
EOT
        end
      else
        if idx == 0 then
          file.print <<EOT
                        if( !strcmp( exp_val->type, "#{obj}") ){
                            exp_val->data.mem_#{obj} = atoi( VAR_tmp_str );
EOT
        else
          file.print <<EOT
                        }else if( !strcmp( exp_val->type, "#{obj}") ){
                            exp_val->data.mem_#{obj} = atoi( VAR_tmp_str );
EOT
        end
      end
    }
    file.print <<EOT
                        }
EOT
  end

#
# 境界値を取得する関数を定義
#

  def print_parse_boundary( file, namespace )
    file.print <<EOT
  CELLCB  *p_cellcb;
  if (VALID_IDX(idx)) {
    p_cellcb = GET_CELLCB(idx);
  }
  else {
    /* エラー処理コードをここに記述します */
  } /* end if VALID_IDX(idx) */

  int r, i, j, k, l;
  jsmn_parser p;
  jsmntok_t t[128];
  char target_path[10];

  sprintf( target_path, "target%d", target_num );

  jsmn_init(&p);
  r = jsmn_parse( &p, VAR_json_str, strlen(VAR_json_str), t, sizeof(t)/sizeof(t[0]) );
  if(r < 0){
    printf( "Failed to parse JSON: %d", r );
    return -1;
  }
  /* Assume the top-level element is an object */
  if( r < 1 || t[0].type != JSMN_OBJECT ){
    printf( "Object expected" );
    return -1;
  }

  for( l = 1; l < r; l++ ){
    if( jsoneq(VAR_json_str, &t[l], target_path) == 0 ){
        if( t[l+1].type != JSMN_OBJECT ){
            printf("Object expected for target");
            return -1;
        }
        i = l + 2;
        for( k = 0; k < t[l+1].size; k++ ){
            if( jsoneq( VAR_json_str, &t[i], ATTR_key_cell ) == 0 ){
                i += 2; /* ignore */
            }else if( jsoneq( VAR_json_str, &t[i], ATTR_key_entry ) == 0 ){
                i += 2; /* ignore */
            }else if( jsoneq( VAR_json_str, &t[i], ATTR_key_function ) == 0 ){
                i += 2; /* ignore */
            }else if( jsoneq( VAR_json_str, &t[i], ATTR_key_arg ) == 0 ){
                i += 3;
            }else if( jsoneq( VAR_json_str, &t[i], ATTR_key_boundary ) == 0 ){
                i += 2; /* 一つ目の境界値 */
                strcpy_n( VAR_tmp_str, t[i].end - t[i].start, VAR_json_str + t[i].start );
                boundary[0] = atoi( VAR_tmp_str );
                i += 1;/* 2つ目の境界値 */
                strcpy_n( VAR_tmp_str, t[i].end - t[i].start, VAR_json_str + t[i].start );
                boundary[1] = atoi( VAR_tmp_str );
                i += 1; /* 配列を抜ける */
            }else if( jsoneq( VAR_json_str, &t[i], ATTR_key_EP_boundary ) == 0 ){
                i += 1;
                if( t[i].type == JSMN_ARRAY ){
                  i += t[i].size;
                } else {
                  printf("ERROR: EP_boundary_val\\n");
                  return -1;
                }
                i += 1;
            }else if( jsoneq( VAR_json_str, &t[i], ATTR_key_exp) == 0 ){
                i += 2;
            }
        }
        VAR_BVT_counter += 1;
        if( VAR_BVT_counter >= t[0].size ){
            return 2; /* もしかしたらtarget2以降があっても終了しちゃうかも */
        }
        return 0;
    }
  }
  return 1;

EOT
  end

  def print_parse_EP_boundary( file, namespace )
    file.print <<EOT
  CELLCB *p_cellcb;
  if(VALID_IDX(idx)) {
    p_cellcb = GET_CELLCB(idx);
  }
  else {
    /* エラー処理コードをここに記述します */
  } /* end if VALID_IDX(idx) */

  int r, i, j, k, l, m, n, arg_size, array_size, EP_size;
  jsmn_parser p;
  jsmntok_t t[128];
  char target_path[10];

  sprintf( target_path, "target%d", target_num );

  jsmn_init(&p);
  r = jsmn_parse( &p, VAR_json_str, strlen(VAR_json_str), t, sizeof(t)/sizeof(t[0]) );
  if(r < 0){
    printf( "Failed to parse JSON: %d\\n", r );
    return -1;
  }

  if( r < 1 || t[0].type != JSMN_OBJECT ){
  printf( "Object expected" );
  return -1;
  }

  for( l = 1; l < r; l++ ){
    if( jsoneq(VAR_json_str, &t[l], target_path) == 0 ){
      if( t[l+1].type != JSMN_OBJECT ){
        printf("Object expected for target\\n");
        return -1;
      }
      i = l + 2;
      for( k = 0; k < t[l+1].size; k++ ){
        if( jsoneq( VAR_json_str, &t[i], ATTR_key_cell ) == 0 ){
            i += 2;
        }else if( jsoneq( VAR_json_str, &t[i], ATTR_key_entry ) == 0 ){
            i += 2;
        }else if( jsoneq( VAR_json_str, &t[i], ATTR_key_function ) == 0 ){
            i += 2;
        }else if( jsoneq( VAR_json_str, &t[i], ATTR_key_arg ) == 0 ){
          i += 1;
          arg_size = t[i].size;
          for( j = 0; j < arg_size; j++ ){
            i += 1;
            if( t[i].type == JSMN_ARRAY ){
              array_size = t[i].type;
              for( m = 0; m < array_size; m++ ){
                i += 1;
                if ( t[i].size > 1 ){
                    i += t[i].size;
                }
              }
            }
            if( t[i].type == JSMN_OBJECT ){
              array_size = t[i].size;
              for( m = 0; m < array_size; m++ ){
                i += 2;
                if( t[i].size > 1 ){
                    i += t[i].size;
                }
              }
            }
          }
          i += 1; /* 配列を抜ける */
        }else if( jsoneq( VAR_json_str, &t[i], ATTR_key_boundary ) == 0 || jsoneq( VAR_json_str, &t[i], ATTR_key_EP_boundary) == 0 ){
          if( jsoneq(VAR_json_str, &t[i], ATTR_key_boundary ) == 0 ){
              i += 1;
              if( t[i].type == JSMN_ARRAY ){
                  if( t[i].size == 2 ) {
                      i += 2; /* boundary_valの対象先が正しく配列であり、その要素数が2なら飛ばす */
                  } else {
                      printf("ERROR: boundary_val\\n");
                      return -1;
                  }
              } else {
                  printf("ERROR: boundary_val\\n");
                  return -1;
              }
              i += 1; /* 配列を抜ける */
          }else if( jsoneq(VAR_json_str, &t[i], ATTR_key_EP_boundary ) == 0 ){
            i += 1;
            if( t[i].type == JSMN_ARRAY ){
                EP_size = t[i].size;
                if( EP_size > 0 ){
                    for( n = 0; n < EP_size; n++ ) {
                        i += 1;
                        strcpy_n( VAR_tmp_str, t[i].end - t[i].start, VAR_json_str + t[i].start );
                        EP_boundary[n] = atoi( VAR_tmp_str );
                    }
                } else {
                    printf("ERROR: EP_boundary_val\\n"); /* 境界を示す配列の要素が0 */
                    return -1;
                }
            } else {
                printf("ERROR: EP_boundary_val\\n"); /* EP_boundary_valが示す先が配列じゃない */
                return -1;
            }
            i += 1; /* 配列を抜ける */
          }
        }else if( jsoneq( VAR_json_str, &t[i], ATTR_key_exp ) == 0 ){
            i += 2;
        }
      }
      VAR_EPT_counter += 1;
      if( VAR_EPT_counter >= t[0].size ){
        return 2;
      }
      return 0;
    }
  }
  return 1;
EOT
  end

# entry function : json_parse_cond の出力
  def print_parse_cond( file, namespace )
    char_list = []

    struct_list = [] # 構造体名
    struct_mem = [] # 構造体のメンバ(tmp)
    struct_mem_type = [] # 構造体のメンバのタイプ(tmp)
    struct_mem_list = [] # 構造体メンバのリスト
    struct_mem_type_list = [] # 構造体メンバのタイプリスト

    arr_list = []
    out_list = []
    num_list = []

    ret_type_list = []


    file.print <<EOT
  CELLCB  *p_cellcb;
  if (VALID_IDX(idx)) {
    p_cellcb = GET_CELLCB(idx);
  }
  else {
    return(E_ID);
  } /* end if VALID_IDX(idx) */

  /* ここに処理本体を記述します #_TEFB_# */
    int r, i, j, k, l, m, array_size, arg_size, cond_size;
    jsmn_parser p;
    jsmntok_t t[128]; /* We expect no more than 128 tokens */

    sprintf( VAR_target_path, "target%d", target_num );

    jsmn_init(&p);
    r = jsmn_parse( &p, VAR_json_str, strlen(VAR_json_str), t, sizeof(t)/sizeof(t[0]) );
    if(r < 0){
      /* Failed to parse JSON */
        return -1;
    }
  /* Assume the top-level element is an object */
    if( r < 1 || t[0].type != JSMN_OBJECT ){
        return -1;
    }

  /* Loop over all keys of the root object */
    for( l = 1; l < r; l++ ){
        if( jsoneq( VAR_json_str, &t[l], VAR_target_path ) == 0 ){
            if( t[l+1].type != JSMN_OBJECT ){
                return -1;
            }
            i = l + 2;
            for( k = 0; k < t[l+1].size; k++ ){
                if( jsoneq( VAR_json_str, &t[i], ATTR_key_region ) == 0 ){
                    i += 2; /* ignore */
                }else if( jsoneq( VAR_json_str, &t[i], ATTR_key_cell ) == 0 ){
                    i += 2; /* ignore */
                }else if( jsoneq( VAR_json_str, &t[i], ATTR_key_entry ) == 0 ){
                    i += 2; /* ignore */
                }else if( jsoneq( VAR_json_str, &t[i], ATTR_key_function ) == 0 ){
                    i += 2; /* ignore */
                }else if( jsoneq( VAR_json_str, &t[i], ATTR_key_arg ) == 0 ) {
                    i += 1;
                    arg_size = t[i].size;
                    for( j = 0; j < arg_size; j++ ){
                        i += 1; // iは各要素を指す
                        if( t[i].type == JSMN_ARRAY ){
                            array_size =  t[i].size;
                            for( m = 0; m < array_size; m++ ){
                                i += 1; // 配列の中身に注目
                                if( t[i].size > 1 ){
                                  i += t[i].size;
                                }
                            }
                        }
                        if( t[i].type == JSMN_OBJECT ){
                            array_size =  t[i].size;
                            for( m = 0; m < array_size; m++){
                                i += 2; // member
                                if( t[i].size > 1 ){
                                  i += t[i].size;
                                }
                            }
                        }
                    }
                    i += 1; // 最後には配列を抜ける
                }else if( jsoneq( VAR_json_str, &t[i], ATTR_key_exp ) == 0 ){
                    i += 2; /* ignore */
                }else if( jsoneq( VAR_json_str, &t[i], ATTR_key_pre_cond ) == 0 ){
                    i += 1; // t[i] はOBJECTを想定
                    if( t[i].type != JSMN_OBJECT ) return -1;
                    cond_size = t[i].size;
                    *pre_cond_num = cond_size;
                    for( j = 0; j < cond_size; j++ ){
                      i += 1; // t[i] は変数名
                      strcpy_n( VAR_tmp_str, t[i].end - t[i].start, VAR_json_str + t[i].start );
EOT
    # 事前条件をパース
    first = true
    namespace.travers_all_celltype{ |ct|
      if  ct.get_namespace_path.to_s =~ /nTECSInfo::/ || \
          ct.get_namespace_path.to_s =~ /::t.*Task.*/ || \
          ct.get_namespace_path.to_s =~ /::tAccessor/ || \
          ct.get_namespace_path.to_s =~ /::tTECSUnit/ || \
          ct.get_namespace_path.to_s =~ /::tJSMN/ || \
          ct.get_namespace_path.to_s =~ /::t.*Kernel/ || \
          ct.get_namespace_path.to_s =~ /::t.*Semaphore/ || \
          ct.get_namespace_path.to_s =~ /::t.*Eventflag/ || \
          ct.get_namespace_path.to_s =~ /::t.*Dataqueue/ || \
          ct.get_namespace_path.to_s =~ /::tInitialize.*/ || \
          ct.get_namespace_path.to_s =~ /::t.*VM/ || \
          ct.get_namespace_path.to_s =~ /::tMain/ || \
          ct.get_namespace_path.to_s =~ /::t.*Alarm/ || \
          ct.get_namespace_path.to_s =~ /::tFixedSizeMemoryPool/ || \
          ct.get_namespace_path.to_s =~ /::tMessageBuffer/ || \
          ct.get_namespace_path.to_s =~ /::tTerminateRoutineBody/ || \
          ct.get_namespace_path.to_s =~ /::t.*HandlerBody/ || \
          ct.get_namespace_path.to_s =~ /::tConfigInterrupt/ || \
          ct.get_namespace_path.to_s =~ /::tCyclic/ || \
          ct.get_namespace_path.to_s =~ /::tMalloc/ then
        # ignnore these celltypes
      else
        ct.get_var_list.each{ |var|
          if first then
            if var.get_type.get_type_str.to_s.include?("*") then
              # ignore
            elsif var.get_type.get_type_str.to_s.include?("struct") then
              # ignore
            elsif var.get_type.get_type_str.to_s.include?("char") || var.get_type.get_type_str.to_s.include?("CHAR") then
              # ignore
            elsif var.get_type.get_type_str.to_s.include?("FIL") || var.get_type.get_type_str.to_s.include?("FATFS") then
              # ignore
            elsif var.get_type.get_type_str.to_s.include?("double64_t") || var.get_type.get_type_str.to_s.include?("float32_t") || \
                  var.get_type.get_type_str.to_s.include?("double") || var.get_type.get_type_str.to_s.include?("float") then
              first = false
              file.print <<EOT
                        if( strcmp( VAR_tmp_str, "#{var.get_name.to_s}" ) ){
                          strcpy_n( pre_cond[j].name, t[i].end - t[i].start, VAR_json_str + t[i].start );
                          i += 1; // t[i] は変数値
                          strcpy_n( VAR_tmp_str, t[i].end - t[i].start, VAR_json_str + t[i].start );
                          pre_cond[j].data.mem_#{var.get_type.get_type_str.to_s.sub('32_t', '').sub('64_t', '')} = atof( VAR_tmp_str );
EOT
            else
              first = false
              file.print <<EOT
                        if( strcmp( VAR_tmp_str, "#{var.get_name.to_s}" ) ){
                          strcpy_n( pre_cond[j].name, t[i].end - t[i].start, VAR_json_str + t[i].start );
                          i += 1; // t[i] は変数値
                          strcpy_n( VAR_tmp_str, t[i].end - t[i].start, VAR_json_str + t[i].start );
                          pre_cond[j].data.mem_#{var.get_type.get_type_str.to_s} = atoi( VAR_tmp_str );
EOT
            end
          else
            if var.get_type.get_type_str.to_s.include?("*") then
              # ignore
            elsif var.get_type.get_type_str.to_s.include?("struct") then
              # ignore
            elsif var.get_type.get_type_str.to_s.include?("char") || var.get_type.get_type_str.to_s.include?("CHAR") then
              # ignore
            elsif var.get_type.get_type_str.to_s.include?("FIL") || var.get_type.get_type_str.to_s.include?("FATFS") then
              # ignore
            elsif var.get_type.get_type_str.to_s.include?("double64_t") || var.get_type.get_type_str.to_s.include?("float32_t") || \
                  var.get_type.get_type_str.to_s.include?("double") || var.get_type.get_type_str.to_s.include?("float") then
              file.print <<EOT
                        }else if( strcmp( VAR_tmp_str, "#{var.get_name.to_s}" ) ){
                          strcpy_n( pre_cond[j].name, t[i].end - t[i].start, VAR_json_str + t[i].start );
                          i += 1; // t[i] は変数値
                          strcpy_n( VAR_tmp_str, t[i].end - t[i].start, VAR_json_str + t[i].start );
                          pre_cond[j].data.mem_#{var.get_type.get_type_str.to_s.sub('32_t', '').sub('64_t', '')} = atof( VAR_tmp_str );
EOT
            else
              file.print <<EOT
                        }else if( strcmp( VAR_tmp_str, "#{var.get_name.to_s}" ) ){
                          strcpy_n( pre_cond[j].name, t[i].end - t[i].start, VAR_json_str + t[i].start );
                          i += 1; // t[i] は変数値
                          strcpy_n( VAR_tmp_str, t[i].end - t[i].start, VAR_json_str + t[i].start );
                          pre_cond[j].data.mem_#{var.get_type.get_type_str.to_s} = atoi( VAR_tmp_str );
EOT
            end
          end
        }
      end
    }

    file.print <<EOT
                        }else{
                          return -1;
                        }
                    }
                    i += 1; // 最後にはOBJECTを抜ける
                }else if( jsoneq( VAR_json_str, &t[i], ATTR_key_post_cond ) == 0 ){
                    i += 1; // t[i] はOBJECTを想定
                    if( t[i].type != JSMN_OBJECT ) return -1;
                    cond_size = t[i].size;
                    *post_cond_num = cond_size;
                    for( j = 0; j < cond_size; j++ ){
                      i += 1; // t[i] は変数名
                      strcpy_n( VAR_tmp_str, t[i].end - t[i].start, VAR_json_str + t[i].start );
EOT
    # 事後条件をパース
    first = true
    namespace.travers_all_celltype{ |ct|
      if  ct.get_namespace_path.to_s =~ /nTECSInfo::/ || \
          ct.get_namespace_path.to_s =~ /::t.*Task.*/ || \
          ct.get_namespace_path.to_s =~ /::tAccessor/ || \
          ct.get_namespace_path.to_s =~ /::tTECSUnit/ || \
          ct.get_namespace_path.to_s =~ /::tJSMN/ || \
          ct.get_namespace_path.to_s =~ /::t.*Kernel/ || \
          ct.get_namespace_path.to_s =~ /::t.*Semaphore/ || \
          ct.get_namespace_path.to_s =~ /::t.*Eventflag/ || \
          ct.get_namespace_path.to_s =~ /::t.*Dataqueue/ || \
          ct.get_namespace_path.to_s =~ /::tInitialize.*/ || \
          ct.get_namespace_path.to_s =~ /::t.*VM/ || \
          ct.get_namespace_path.to_s =~ /::tMain/ || \
          ct.get_namespace_path.to_s =~ /::t.*Alarm/ || \
          ct.get_namespace_path.to_s =~ /::tFixedSizeMemoryPool/ || \
          ct.get_namespace_path.to_s =~ /::tMessageBuffer/ || \
          ct.get_namespace_path.to_s =~ /::tTerminateRoutineBody/ || \
          ct.get_namespace_path.to_s =~ /::t.*HandlerBody/ || \
          ct.get_namespace_path.to_s =~ /::tConfigInterrupt/ || \
          ct.get_namespace_path.to_s =~ /::tCyclic/ || \
          ct.get_namespace_path.to_s =~ /::tMalloc/ then
        # ignnore these celltypes
      else
        ct.get_var_list.each{ |var|
          if first then
            if var.get_type.get_type_str.to_s.include?("*") then
              # ignore
            elsif var.get_type.get_type_str.to_s.include?("struct") then
              # ignore
            elsif var.get_type.get_type_str.to_s.include?("char") || var.get_type.get_type_str.to_s.include?("CHAR") then
              # ignore
            elsif var.get_type.get_type_str.to_s.include?("FIL") || var.get_type.get_type_str.to_s.include?("FATFS") then
              # ignore
            elsif var.get_type.get_type_str.to_s.include?("double64_t") || var.get_type.get_type_str.to_s.include?("float32_t") || \
                  var.get_type.get_type_str.to_s.include?("double") || var.get_type.get_type_str.to_s.include?("float") then
              first = false
              file.print <<EOT
                        if( strcmp( VAR_tmp_str, "#{var.get_name.to_s}" ) ){
                          strcpy_n( post_cond[j].name, t[i].end - t[i].start, VAR_json_str + t[i].start );
                          i += 1; // t[i] は変数値
                          strcpy_n( VAR_tmp_str, t[i].end - t[i].start, VAR_json_str + t[i].start );
                          post_cond[j].data.mem_#{var.get_type.get_type_str.to_s.sub('32_t', '').sub('64_t', '')} = atof( VAR_tmp_str );
EOT
            else
              first = false
              file.print <<EOT
                        if( strcmp( VAR_tmp_str, "#{var.get_name.to_s}" ) ){
                          strcpy_n( post_cond[j].name, t[i].end - t[i].start, VAR_json_str + t[i].start );
                          i += 1; // t[i] は変数値
                          strcpy_n( VAR_tmp_str, t[i].end - t[i].start, VAR_json_str + t[i].start );
                          post_cond[j].data.mem_#{var.get_type.get_type_str.to_s.sub('32_t', '').sub('64_t', '')} = atoi( VAR_tmp_str );
EOT
            end
          else
            if var.get_type.get_type_str.to_s.include?("*") then
              # ignore
            elsif var.get_type.get_type_str.to_s.include?("struct") then
              # ignore
            elsif var.get_type.get_type_str.to_s.include?("char") || var.get_type.get_type_str.to_s.include?("CHAR") then
              # ignore
            elsif var.get_type.get_type_str.to_s.include?("FIL") || var.get_type.get_type_str.to_s.include?("FATFS") then
              # ignore
            elsif var.get_type.get_type_str.to_s.include?("double64_t") || var.get_type.get_type_str.to_s.include?("float32_t") || \
                  var.get_type.get_type_str.to_s.include?("double") || var.get_type.get_type_str.to_s.include?("float") then
            file.print <<EOT
                        }else if( strcmp( VAR_tmp_str, "#{var.get_name.to_s}" ) ){
                          strcpy_n( post_cond[j].name, t[i].end - t[i].start, VAR_json_str + t[i].start );
                          i += 1; // t[i] は変数値
                          strcpy_n( VAR_tmp_str, t[i].end - t[i].start, VAR_json_str + t[i].start );
                          post_cond[j].data.mem_#{var.get_type.get_type_str.to_s.sub('32_t', '').sub('64_t', '')} = atof( VAR_tmp_str );
EOT
            else
            file.print <<EOT
                        }else if( strcmp( VAR_tmp_str, "#{var.get_name.to_s}" ) ){
                          strcpy_n( post_cond[j].name, t[i].end - t[i].start, VAR_json_str + t[i].start );
                          i += 1; // t[i] は変数値
                          strcpy_n( VAR_tmp_str, t[i].end - t[i].start, VAR_json_str + t[i].start );
                          post_cond[j].data.mem_#{var.get_type.get_type_str.to_s} = atoi( VAR_tmp_str );
EOT
            end
          end
        }
      end
    }
    file.print <<EOT
                        }else{
                          return -1;
                        }
EOT
    file.print <<EOT
                    }
                    i += 1; // 最後にはOBJECTを抜ける
                }else{
                  //  printf( "Unexpected key: %.*s\\n", t[i].end-t[i].start, VAR_json_str + t[i].start );
                    return -1;
                }
            }
            return 0;
        }
    }
    return 1;
EOT

  end

  #=== 後ろの CDL コードを生成
  #プラグインの後ろの CDL コードを生成
  #file:: File:
  def self.gen_post_code( file )

  end

# プロトタイプ宣言などを定義
  def gen_preamble( file, b_singleton, ct_name, global_ct_name )
    file.print <<EOT
#include "tJSMN_tecsgen.h"
#include <stdio.h>
/*#include <stdlib.h>*/
#include <jsmn.h>
/*#include <ff.h>*/
#define N 128

static int
jsoneq( const char *json, jsmntok_t *tok, const char *s);
static void
strcpy_n( char_t *str1, int num, const char *str2 );
EOT
  end

# 非受け口関数
  def gen_postamble( file, b_singleton, ct_name, global_ct_name )
    file.print <<EOT
static int
jsoneq(const char *json, jsmntok_t *tok, const char *s)
{
    if( tok->type == JSMN_STRING && (int) strlen(s) == tok->end - tok->start
        && strncmp(json + tok->start, s, tok->end - tok->start) == 0 ){
        return 0;
    }
    return -1;
}

static void
strcpy_n( char_t *str1, int num, const char *str2 )
{
    int i;
    for(i = 0; i < num; i++){
        str1[i] = str2[i];
    }
    str1[num] = '\\0';
}
/* 以下jsmn.cより引用 */
/**
 * Allocates a fresh unused token from the token pool.
 */
static jsmntok_t *jsmn_alloc_token(jsmn_parser *parser,
        jsmntok_t *tokens, size_t num_tokens) {
    jsmntok_t *tok;
    if (parser->toknext >= num_tokens) {
        return NULL;
    }
    tok = &tokens[parser->toknext++];
    tok->start = tok->end = -1;
    tok->size = 0;
#ifdef JSMN_PARENT_LINKS
    tok->parent = -1;
#endif
    return tok;
}
/**
 * Fills token type and boundaries.
 */
static void jsmn_fill_token(jsmntok_t *token, jsmntype_t type,
                            int start, int end) {
    token->type = type;
    token->start = start;
    token->end = end;
    token->size = 0;
}
/**
 * Fills next available token with JSON primitive.
 */
static int jsmn_parse_primitive(jsmn_parser *parser, const char *js,
        size_t len, jsmntok_t *tokens, size_t num_tokens) {
    jsmntok_t *token;
    int start;
    start = parser->pos;
    for (; parser->pos < len && js[parser->pos] != '\\0'; parser->pos++) {
        switch (js[parser->pos]) {
#ifndef JSMN_STRICT
            /* In strict mode primitive must be followed by "," or "}" or "]" */
            case ':':
#endif
            case '\\t' : case '\\r' : case '\\n' : case ' ' :
            case ','  : case ']'  : case '}' :
                goto found;
        }
        if (js[parser->pos] < 32 || js[parser->pos] >= 127) {
            parser->pos = start;
            return JSMN_ERROR_INVAL;
        }
    }
#ifdef JSMN_STRICT
    /* In strict mode primitive must be followed by a comma/object/array */
    parser->pos = start;
    return JSMN_ERROR_PART;
#endif
found:
    if (tokens == NULL) {
        parser->pos--;
        return 0;
    }
    token = jsmn_alloc_token(parser, tokens, num_tokens);
    if (token == NULL) {
        parser->pos = start;
        return JSMN_ERROR_NOMEM;
    }
    jsmn_fill_token(token, JSMN_PRIMITIVE, start, parser->pos);
#ifdef JSMN_PARENT_LINKS
    token->parent = parser->toksuper;
#endif
    parser->pos--;
    return 0;
}
/**
 * Fills next token with JSON string.
 */
static int jsmn_parse_string(jsmn_parser *parser, const char *js,
        size_t len, jsmntok_t *tokens, size_t num_tokens) {
    jsmntok_t *token;
    int start = parser->pos;
    parser->pos++;
    /* Skip starting quote */
    for (; parser->pos < len && js[parser->pos] != '\\0'; parser->pos++) {
        char c = js[parser->pos];
        /* Quote: end of string */
        if (c == '\\"') {
            if (tokens == NULL) {
                return 0;
            }
            token = jsmn_alloc_token(parser, tokens, num_tokens);
            if (token == NULL) {
                parser->pos = start;
                return JSMN_ERROR_NOMEM;
            }
            jsmn_fill_token(token, JSMN_STRING, start+1, parser->pos);
#ifdef JSMN_PARENT_LINKS
            token->parent = parser->toksuper;
#endif
            return 0;
        }
        /* Backslash: Quoted symbol expected */
        if (c == '\\\\' && parser->pos + 1 < len) {
            int i;
            parser->pos++;
            switch (js[parser->pos]) {
                /* Allowed escaped symbols */
                case '\"': case '/' : case '\\\\' : case 'b' :
                case 'f' : case 'r' : case 'n'  : case 't' :
                    break;
                /* Allows escaped symbol */
                case 'u':
                    parser->pos++;
                    for(i = 0; i < 4 && parser->pos < len && js[parser->pos] != '\\0'; i++) {
                        /* If it isnot a hex character we have an error */
                        if(!((js[parser->pos] >= 48 && js[parser->pos] <= 57) || /* 0-9 */
                                    (js[parser->pos] >= 65 && js[parser->pos] <= 70) || /* A-F */
                                    (js[parser->pos] >= 97 && js[parser->pos] <= 102))) { /* a-f */
                            parser->pos = start;
                            return JSMN_ERROR_INVAL;
                        }
                        parser->pos++;
                    }
                    parser->pos--;
                    break;
                /* Unexpected symbol */
                default:
                    parser->pos = start;
                    return JSMN_ERROR_INVAL;
            }
        }
    }
    parser->pos = start;
    return JSMN_ERROR_PART;
}
/**
 * Parse JSON string and fill tokens.
 */
int jsmn_parse(jsmn_parser *parser, const char *js, size_t len,
        jsmntok_t *tokens, unsigned int num_tokens) {
    int r;
    int i;
    jsmntok_t *token;
    int count = parser->toknext;
    for (; parser->pos < len && js[parser->pos] != '\\0'; parser->pos++) {
        char c;
        jsmntype_t type;
        c = js[parser->pos];
        switch (c) {
            case '{': case '[':
                count++;
                if (tokens == NULL) {
                    break;
                }
                token = jsmn_alloc_token(parser, tokens, num_tokens);
                if (token == NULL)
                    return JSMN_ERROR_NOMEM;
                if (parser->toksuper != -1) {
                    tokens[parser->toksuper].size++;
#ifdef JSMN_PARENT_LINKS
                    token->parent = parser->toksuper;
#endif
                }
                token->type = (c == '{' ? JSMN_OBJECT : JSMN_ARRAY);
                token->start = parser->pos;
                parser->toksuper = parser->toknext - 1;
                break;
            case '}': case ']':
                if (tokens == NULL)
                    break;
                type = (c == '}' ? JSMN_OBJECT : JSMN_ARRAY);
#ifdef JSMN_PARENT_LINKS
                if (parser->toknext < 1) {
                    return JSMN_ERROR_INVAL;
                }
                token = &tokens[parser->toknext - 1];
                for (;;) {
                    if (token->start != -1 && token->end == -1) {
                        if (token->type != type) {
                            return JSMN_ERROR_INVAL;
                        }
                        token->end = parser->pos + 1;
                        parser->toksuper = token->parent;
                        break;
                    }
                    if (token->parent == -1) {
                        if(token->type != type || parser->toksuper == -1) {
                            return JSMN_ERROR_INVAL;
                        }
                        break;
                    }
                    token = &tokens[token->parent];
                }
#else
                for (i = parser->toknext - 1; i >= 0; i--) {
                    token = &tokens[i];
                    if (token->start != -1 && token->end == -1) {
                        if (token->type != type) {
                            return JSMN_ERROR_INVAL;
                        }
                        parser->toksuper = -1;
                        token->end = parser->pos + 1;
                        break;
                    }
                }
                /* Error if unmatched closing bracket */
                if (i == -1) return JSMN_ERROR_INVAL;
                for (; i >= 0; i--) {
                    token = &tokens[i];
                    if (token->start != -1 && token->end == -1) {
                        parser->toksuper = i;
                        break;
                    }
                }
#endif
                break;
            case '\\"':
                r = jsmn_parse_string(parser, js, len, tokens, num_tokens);
                if (r < 0) return r;
                count++;
                if (parser->toksuper != -1 && tokens != NULL)
                    tokens[parser->toksuper].size++;
                break;
            case '\\t' : case '\\r' : case '\\n' : case ' ':
                break;
            case ':':
                parser->toksuper = parser->toknext - 1;
                break;
            case ',':
                if (tokens != NULL && parser->toksuper != -1 &&
                        tokens[parser->toksuper].type != JSMN_ARRAY &&
                        tokens[parser->toksuper].type != JSMN_OBJECT) {
#ifdef JSMN_PARENT_LINKS
                    parser->toksuper = tokens[parser->toksuper].parent;
#else
                    for (i = parser->toknext - 1; i >= 0; i--) {
                        if (tokens[i].type == JSMN_ARRAY || tokens[i].type == JSMN_OBJECT) {
                            if (tokens[i].start != -1 && tokens[i].end == -1) {
                                parser->toksuper = i;
                                break;
                            }
                        }
                    }
#endif
                }
                break;
#ifdef JSMN_STRICT
            /* In strict mode primitives are: numbers and booleans */
            case '-': case '0': case '1' : case '2': case '3' : case '4':
            case '5': case '6': case '7' : case '8': case '9':
            case 't': case 'f': case 'n' :
                /* And they must not be keys of the object */
                if (tokens != NULL && parser->toksuper != -1) {
                    jsmntok_t *t = &tokens[parser->toksuper];
                    if (t->type == JSMN_OBJECT ||
                            (t->type == JSMN_STRING && t->size != 0)) {
                        return JSMN_ERROR_INVAL;
                    }
                }
#else
            /* In non-strict mode every unquoted value is a primitive */
            default:
#endif
                r = jsmn_parse_primitive(parser, js, len, tokens, num_tokens);
                if (r < 0) return r;
                count++;
                if (parser->toksuper != -1 && tokens != NULL)
                    tokens[parser->toksuper].size++;
                break;
#ifdef JSMN_STRICT
            /* Unexpected char in strict mode */
            default:
                return JSMN_ERROR_INVAL;
#endif
        }
    }
    if (tokens != NULL) {
        for (i = parser->toknext - 1; i >= 0; i--) {
            /* Unmatched opened object or array */
            if (tokens[i].start != -1 && tokens[i].end == -1) {
                return JSMN_ERROR_PART;
            }
        }
    }
    return count;
}
/**
 * Creates a new parser based over a given  buffer with an array of tokens
 * available.
 */
void jsmn_init(jsmn_parser *parser) {
    parser->pos = 0;
    parser->toknext = 0;
    parser->toksuper = -1;
}
EOT
  end

end