/* #[<PREAMBLE>]#
 * #[<...>]# から #[</...>]# で囲まれたコメントは編集しないでください
 * tecsmerge によるマージに使用されます
 *
 * 属性アクセスマクロ #_CAAM_#
 * NAME_LEN         int16_t          ATTR_NAME_LEN
 * ARG_NAME_LEN     int16_t          ATTR_ARG_NAME_LEN
 * ARG_DIM          int16_t          ATTR_ARG_DIM
 * TARGET_NUM       int16_t          ATTR_TARGET_NUM
 * cell_path        char_t*          VAR_cell_path
 * celltype_path    char_t*          VAR_celltype_path
 * entry_path       char_t*          VAR_entry_path
 * entry_path_tmp   char_t*          VAR_entry_path_tmp
 * signature_path   char_t*          VAR_signature_path
 * function_path    char_t*          VAR_function_path
 * function_path_tmp char_t*          VAR_function_path_tmp
 * arg_num          int8_t           VAR_arg_num
 * exp_type         char_t*          VAR_exp_type
 * arg              char_t [32][128] VAR_arg
 * arg_type         char_t [32][128] VAR_arg_type
 * find_entry       int8_t           VAR_find_entry
 * find_func        int8_t           VAR_find_func
 *
 * 呼び口関数 #_TCPF_#
 * call port: cUnit signature: sTECSUnit context:task
 *   void           cUnit_main( const char_t* cell_path, const char_t* entry_path, const char_t* signature_path, const char_t* function_path, const struct tecsunit_obj* arguments, const struct tecsunit_obj* exp_val );
 * call port: cJSMN signature: sJSMN context:task
 *   ER             cJSMN_json_open( );
 *   ER             cJSMN_json_parse_path( char_t* c_path, char_t* e_path, char_t* f_path, int target_num, int btr );
 *   ER             cJSMN_json_parse_arg( struct tecsunit_obj* arguments, struct tecsunit_obj* exp_val, int* arg_num, int target_num, int btr );
 * call port: cTECSInfo signature: nTECSInfo_sTECSInfo context:task
 *   ER             cTECSInfo_findNamespace( const char_t* namespace_path, Descriptor( nTECSInfo_sNamespaceInfo )* nsDesc );
 *   ER             cTECSInfo_findRegion( const char_t* namespace_path, Descriptor( nTECSInfo_sRegionInfo )* regionDesc );
 *   ER             cTECSInfo_findSignature( const char_t* namespace_path, Descriptor( nTECSInfo_sSignatureInfo )* signatureDesc );
 *   ER             cTECSInfo_findCelltype( const char_t* namespace_path, Descriptor( nTECSInfo_sCelltypeInfo )* celltypeDesc );
 *   ER             cTECSInfo_findCell( const char_t* namespace_path, Descriptor( nTECSInfo_sCellInfo )* cellDesc );
 *   ER             cTECSInfo_findRawEntryDescriptor( const char_t* namespace_path, Descriptor( nTECSInfo_sRawEntryDescriptorInfo )* rawEntryDescDesc, Descriptor( nTECSInfo_sEntryInfo )* entryDesc );
 *   ER             cTECSInfo_findRawEntryDescriptor_unsafe( const char_t* namespace_path, uint32_t subsc, void** rawDesc );
 * call port: cNSInfo signature: nTECSInfo_sNamespaceInfo context:task optional:true
 *   bool_t     is_cNSInfo_joined()                     check if joined
 *   ER             cNSInfo_getName( char_t* name, int_t max_len );
 *   uint16_t       cNSInfo_getNameLength( );
 *   uint32_t       cNSInfo_getNNamespace( );
 *   ER             cNSInfo_getNamespaceInfo( uint32_t ith, Descriptor( nTECSInfo_sNamespaceInfo )* des );
 *   uint32_t       cNSInfo_getNSignature( );
 *   ER             cNSInfo_getSignatureInfo( uint32_t ith, Descriptor( nTECSInfo_sSignatureInfo )* des );
 *   uint32_t       cNSInfo_getNCelltype( );
 *   ER             cNSInfo_getCelltypeInfo( uint32_t ith, Descriptor( nTECSInfo_sCelltypeInfo )* des );
 *   [dynamic, optional]
 *      void           cNSInfo_set_descriptor( Descriptor( nTECSInfo_sNamespaceInfo ) desc );
 *      void           cNSInfo_unjoin(  );
 * call port: cRegionInfo signature: nTECSInfo_sRegionInfo context:task optional:true
 *   bool_t     is_cRegionInfo_joined()                     check if joined
 *   ER             cRegionInfo_getName( char_t* name, int_t max_len );
 *   uint16_t       cRegionInfo_getNameLength( );
 *   uint32_t       cRegionInfo_getNCell( );
 *   ER             cRegionInfo_getCellInfo( uint32_t ith, Descriptor( nTECSInfo_sCellInfo )* des );
 *   uint32_t       cRegionInfo_getNRegion( );
 *   ER             cRegionInfo_getRegionInfo( uint32_t ith, Descriptor( nTECSInfo_sRegionInfo )* des );
 *   [dynamic, optional]
 *      void           cRegionInfo_set_descriptor( Descriptor( nTECSInfo_sRegionInfo ) desc );
 *      void           cRegionInfo_unjoin(  );
 * call port: cCellInfo signature: nTECSInfo_sCellInfo context:task optional:true
 *   bool_t     is_cCellInfo_joined()                     check if joined
 *   ER             cCellInfo_getName( char_t* name, int_t max_len );
 *   uint16_t       cCellInfo_getNameLength( );
 *   uint32_t       cCellInfo_getNRawEntryDescriptorInfo( );
 *   ER             cCellInfo_getRawEntryDescriptorInfo( int_t index, Descriptor( nTECSInfo_sRawEntryDescriptorInfo )* desc );
 *   void           cCellInfo_getCelltypeInfo( Descriptor( nTECSInfo_sCelltypeInfo )* desc );
 *   void           cCellInfo_getCBP( void** cbp );
 *   void           cCellInfo_getINIBP( void** inibp );
 *   [dynamic, optional]
 *      void           cCellInfo_set_descriptor( Descriptor( nTECSInfo_sCellInfo ) desc );
 *      void           cCellInfo_unjoin(  );
 * call port: cSignatureInfo signature: nTECSInfo_sSignatureInfo context:task optional:true
 *   bool_t     is_cSignatureInfo_joined()                     check if joined
 *   ER             cSignatureInfo_getName( char_t* name, int_t max_len );
 *   uint16_t       cSignatureInfo_getNameLength( );
 *   uint32_t       cSignatureInfo_getNFunction( );
 *   ER             cSignatureInfo_getFunctionInfo( uint32_t ith, Descriptor( nTECSInfo_sFunctionInfo )* desc );
 *   [dynamic, optional]
 *      void           cSignatureInfo_set_descriptor( Descriptor( nTECSInfo_sSignatureInfo ) desc );
 *      void           cSignatureInfo_unjoin(  );
 * call port: cCelltypeInfo signature: nTECSInfo_sCelltypeInfo context:task optional:true
 *   bool_t     is_cCelltypeInfo_joined()                     check if joined
 *   ER             cCelltypeInfo_getName( char_t* name, int_t max_len );
 *   uint16_t       cCelltypeInfo_getNameLength( );
 *   uint32_t       cCelltypeInfo_getNAttr( );
 *   ER             cCelltypeInfo_getAttrInfo( uint32_t ith, Descriptor( nTECSInfo_sVarDeclInfo )* desc );
 *   uint32_t       cCelltypeInfo_getNVar( );
 *   ER             cCelltypeInfo_getVarInfo( uint32_t ith, Descriptor( nTECSInfo_sVarDeclInfo )* desc );
 *   uint32_t       cCelltypeInfo_getNCall( );
 *   ER             cCelltypeInfo_getCallInfo( uint32_t ith, Descriptor( nTECSInfo_sCallInfo )* desc );
 *   uint32_t       cCelltypeInfo_getNEntry( );
 *   ER             cCelltypeInfo_getEntryInfo( uint32_t ith, Descriptor( nTECSInfo_sEntryInfo )* desc );
 *   bool_t         cCelltypeInfo_isSingleton( );
 *   bool_t         cCelltypeInfo_isIDX_is_ID( );
 *   uint32_t       cCelltypeInfo_sizeOfCB( );
 *   uint32_t       cCelltypeInfo_sizeOfINIB( );
 *   [dynamic, optional]
 *      void           cCelltypeInfo_set_descriptor( Descriptor( nTECSInfo_sCelltypeInfo ) desc );
 *      void           cCelltypeInfo_unjoin(  );
 * call port: cVarDeclInfo signature: nTECSInfo_sVarDeclInfo context:task optional:true
 *   bool_t     is_cVarDeclInfo_joined()                     check if joined
 *   ER             cVarDeclInfo_getName( char_t* name, int_t max_len );
 *   uint16_t       cVarDeclInfo_getNameLength( );
 *   void           cVarDeclInfo_getLocationInfo( uint32_t* offset, int8_t* place );
 *   void           cVarDeclInfo_getTypeInfo( Descriptor( nTECSInfo_sTypeInfo )* desc );
 *   void           cVarDeclInfo_getSizeIsExpr( char_t* expr_str, int32_t max_len );
 *   ER             cVarDeclInfo_getSizeIs( uint32_t* size, const void* p_cb );
 *   [dynamic, optional]
 *      void           cVarDeclInfo_set_descriptor( Descriptor( nTECSInfo_sVarDeclInfo ) desc );
 *      void           cVarDeclInfo_unjoin(  );
 * call port: cTypeInfo signature: nTECSInfo_sTypeInfo context:task optional:true
 *   bool_t     is_cTypeInfo_joined()                     check if joined
 *   ER             cTypeInfo_getName( char_t* name, int_t max_len );
 *   uint16_t       cTypeInfo_getNameLength( );
 *   uint32_t       cTypeInfo_getSize( );
 *   int8_t         cTypeInfo_getKind( );
 *   uint32_t       cTypeInfo_getNType( );
 *   ER             cTypeInfo_getTypeInfo( Descriptor( nTECSInfo_sTypeInfo )* desc );
 *   uint32_t       cTypeInfo_getNMember( );
 *   ER             cTypeInfo_getMemberInfo( uint32_t ith, Descriptor( nTECSInfo_sVarDeclInfo )* desc );
 *   [dynamic, optional]
 *      void           cTypeInfo_set_descriptor( Descriptor( nTECSInfo_sTypeInfo ) desc );
 *      void           cTypeInfo_unjoin(  );
 * call port: cFunctionInfo signature: nTECSInfo_sFunctionInfo context:task optional:true
 *   bool_t     is_cFunctionInfo_joined()                     check if joined
 *   ER             cFunctionInfo_getName( char_t* name, int_t max_len );
 *   uint16_t       cFunctionInfo_getNameLength( );
 *   void           cFunctionInfo_getReturnTypeInfo( Descriptor( nTECSInfo_sTypeInfo )* desc );
 *   uint32_t       cFunctionInfo_getNParam( );
 *   ER             cFunctionInfo_getParamInfo( uint32_t ith, Descriptor( nTECSInfo_sParamInfo )* param );
 *   [dynamic, optional]
 *      void           cFunctionInfo_set_descriptor( Descriptor( nTECSInfo_sFunctionInfo ) desc );
 *      void           cFunctionInfo_unjoin(  );
 * call port: cParamInfo signature: nTECSInfo_sParamInfo context:task optional:true
 *   bool_t     is_cParamInfo_joined()                     check if joined
 *   ER             cParamInfo_getName( char_t* name, int_t max_len );
 *   uint16_t       cParamInfo_getNameLength( );
 *   ER             cParamInfo_getTypeInfo( Descriptor( nTECSInfo_sTypeInfo )* desc );
 *   ER             cParamInfo_getDir( int8_t* dir );
 *   [dynamic, optional]
 *      void           cParamInfo_set_descriptor( Descriptor( nTECSInfo_sParamInfo ) desc );
 *      void           cParamInfo_unjoin(  );
 * call port: cEntryInfo signature: nTECSInfo_sEntryInfo context:task optional:true
 *   bool_t     is_cEntryInfo_joined()                     check if joined
 *   ER             cEntryInfo_getName( char_t* name, int_t max_len );
 *   uint16_t       cEntryInfo_getNameLength( );
 *   void           cEntryInfo_getSignatureInfo( Descriptor( nTECSInfo_sSignatureInfo )* desc );
 *   uint32_t       cEntryInfo_getArraySize( );
 *   bool_t         cEntryInfo_isInline( );
 *   [dynamic, optional]
 *      void           cEntryInfo_set_descriptor( Descriptor( nTECSInfo_sEntryInfo ) desc );
 *      void           cEntryInfo_unjoin(  );
 *
 * #[</PREAMBLE>]# */

/* プロトタイプ宣言や変数の定義をここに書きます #_PAC_# */
#include "tTaskMain_tecsgen.h"
#include <stdio.h>
#include <jsmn.h>
// #include "json_struct.h"

#ifndef E_OK
#define E_OK    0       /* success */
#define E_ID    (-18)   /* illegal ID */
#endif

static void
print_cell_by_path( CELLCB *p_cellcb, char_t *path , int *flag );
static void
print_cell( CELLCB *p_cellcb, Descriptor( nTECSInfo_sCellInfo )  CELLdesc );
static void
print_signature( CELLCB *p_cellcb, Descriptor( nTECSInfo_sSignatureInfo )  signatureDesc );
static void
print_function( CELLCB *p_cellcb, Descriptor( nTECSInfo_sFunctionInfo ) functionDesc );
static void
print_param( CELLCB *p_cellcb, Descriptor( nTECSInfo_sParamInfo ) paramDesc, int num );
static void
print_celltype( CELLCB   *p_cellcb, Descriptor( nTECSInfo_sCelltypeInfo )  CTdesc );
static void
print_entry(CELLCB  *p_cellcb, Descriptor( nTECSInfo_sEntryInfo )  Edesc );
static void
allocate_precond( CELLCB *p_cellcb );
static void
check_postcond( CELLCB *p_cellcb );
int
isNull( const char *str );
/* 受け口関数 #_TEPF_# */
/* #[<ENTRY_PORT>]# eBody
 * entry port: eBody
 * signature:  sTaskBody
 * context:    task
 * #[</ENTRY_PORT>]# */

/* #[<ENTRY_FUNC>]# eBody_main
 * name:         eBody_main
 * global_name:  tTaskMain_eBody_main
 * oneway:       false
 * #[</ENTRY_FUNC>]# */
void
eBody_main(CELLIDX idx)
{
    CELLCB  *p_cellcb;
    ER      ercd, ercd2, ercd3;
    uint32_t  n;
    Descriptor( nTECSInfo_sNamespaceInfo ) NSdesc;
    Descriptor( nTECSInfo_sRegionInfo )    RGNdesc;

    if (VALID_IDX(idx)) {
        p_cellcb = GET_CELLCB(idx);
    }
    else {
        /* エラー処理コードをここに記述します */
    } /* end if VALID_IDX(idx) */

    /* ここに処理本体を記述します #_TEFB_# */
    struct tecsunit_obj arguments[ATTR_ARG_DIM]; /* せるTaskMainの持つ属性ARG_DIM = 32 / 多分引数に関する32個の構造体*/
    struct tecsunit_obj exp_val; /* 期待値に関する構造体 */
    int boundary[ATTR_BOUNDARY_DIM], EP_boundary[ATTR_BOUNDARY_DIM];
    int i, j, arg_num, flag = 0;
    FILE *fp;

    if( ( fp = fopen("test_result.txt", "w") ) == NULL ) {
        printf("Failed to opne file\n");
        return;
    }

    ercd = cJSMN_json_open();
    if( ercd != E_OK ) return;
     /* 正しくcJSMN_json_parseが終了すれば続ける / たぶんセルJSMNのセル変数json_strにテストケースが文字列として格納される */

    strcpy(VAR_result_str, "\n| Test Method | Target Function | Result |\n|:---:|:---:|:---:|\n");

    /* j = 1~ATTR_TARGET_NUM(100) */
    for( j = 1; j < ATTR_TARGET_NUM + 1 ; j++ ) {
        /* 初期化 */
        VAR_find_entry = 0;
        VAR_find_func = 0;
        memset( arguments, 0 , sizeof(arguments) );
        memset( VAR_arg, 0 , sizeof(VAR_arg) );
        memset( VAR_arg_type, 0 , sizeof(VAR_arg_type) );


        ercd = cJSMN_json_parse_path( VAR_cell_path, VAR_entry_path_tmp, VAR_function_path_tmp, j, ATTR_NAME_LEN );
        if( ercd == 1 ) continue; /* そのtarget#は見つからなかった */

        if( ercd == -1 ) return; /* jsmnエラー */

        printf( "** Target%d\n", j );
        printf( "--- JSON ---\n" );
        printf( "- Cell: \"%s\"\n", VAR_cell_path );
        printf( "- Entry: \"%s\"\n", VAR_entry_path_tmp );
        printf( "- Function: \"%s\"\n", VAR_function_path_tmp );


        puts("");
        printf( "--- TECSInfo ---\n" );
        print_cell_by_path( p_cellcb, VAR_cell_path , &flag );

        if( flag ){
            printf( "Error: Cell \"%s\" cannot found\n", VAR_cell_path );
            return;
        }else if( isNull(VAR_entry_path) ){
            printf( "Error: Entry \"%s\" cannot found\n", VAR_entry_path_tmp );
            return;
        }else if( isNull(VAR_function_path) ){
            printf( "Error: Function \"%s\" cannot found\n", VAR_function_path_tmp );
            return;
        }
        printf( "- Celltype: \"%s\"\n", VAR_celltype_path );
        printf( "- Signature: \"%s\"\n", VAR_signature_path );
        printf( "- number of arg: %d\n", VAR_arg_num );

        for( i = 0; i < VAR_arg_num; i++ ){
            printf( "  %d %s %s\n", i+1, VAR_arg_type[i], VAR_arg[i] );
            strcpy( arguments[i].type, VAR_arg_type[i] );
        }
        strcpy( exp_val.type, VAR_exp_type );
        printf( "- Return Type: %s\n", exp_val.type );
        // argumentsにはtypeのみがTECSInfoにより入っている状態。

        /* ----------cJSON_json_parse_arg-------------- */
        ercd = cJSMN_json_parse_arg( arguments, &exp_val, &arg_num, j, ATTR_NAME_LEN );
        if( ercd == -1 ) return; /* jsmnエラー */

        if( arg_num != VAR_arg_num ){
            printf( "Error: Wrong number of arguments\n" );
            printf( "You expected %d arguments. Function \"%s\" has %d arguments\n",
                arg_num, VAR_function_path, VAR_arg_num );
        }
        cUnit_main( VAR_cell_path, VAR_entry_path, VAR_signature_path, VAR_function_path, VAR_result_str, arguments, &exp_val );
        printf("\n");

        ercd2 = cJSMN_json_parse_boundary( &boundary, j, ATTR_NAME_LEN );
        if( ercd2 == -1 ) return;

        cUnit_boundary_value_test( VAR_cell_path, VAR_entry_path, VAR_signature_path, VAR_function_path, boundary, &exp_val );
        printf("\n\n");

        ercd3 = cJSMN_json_parse_EP_boundary( &EP_boundary, j, ATTR_NAME_LEN );
        if ( ercd3 == -1 ) return;

        cUnit_equivalence_partitioning_test( VAR_cell_path, VAR_entry_path, VAR_signature_path, VAR_function_path, EP_boundary, &exp_val );
        printf("\n\n");

        if( ercd == 2 ){
            printf( "All targets are checked\n" );
            fprintf(fp, VAR_result_str);
            fclose(fp);
            return;
        }
    }

    /* 正しく処理が終了しなかった場合に出力するメッセージ */
    if( j > ATTR_TARGET_NUM ){
        printf( "Error: Too many targets or keyword is wrong.\n" );
        printf( "Keyword is \"target#\" and keep the target number 1 ~ %d\n", ATTR_TARGET_NUM );
    }
    // fputs(fp, VAR_result_str);
    fclose(fp);
}

/* #[<POSTAMBLE>]#
 *   これより下に非受け口関数を書きます
 * #[</POSTAMBLE>]#*/

static void
print_cell_by_path( CELLCB *p_cellcb, char_t *path , int *flag )
{
    Descriptor( nTECSInfo_sCellInfo )  desc;
    ER    ercd;

    ercd = cTECSInfo_findCell( path, &desc );
    if( ercd == E_OK ){
        print_cell( p_cellcb, desc );
    }
    else{
        *flag = 1;
    }
}

static void
print_cell( CELLCB  *p_cellcb, Descriptor( nTECSInfo_sCellInfo )  CELLdesc )
{
    Descriptor( nTECSInfo_sCelltypeInfo ) CTdesc;
    void  *cbp, *inibp;

    cCellInfo_set_descriptor( CELLdesc );

    cCellInfo_getCelltypeInfo( &CTdesc );

    /* celltype info */
    print_celltype( p_cellcb, CTdesc );
}

static void
print_celltype( CELLCB  *p_cellcb, Descriptor( nTECSInfo_sCelltypeInfo )  CTdesc )
{

    Descriptor( nTECSInfo_sEntryInfo ) entryDesc;
    int i, n;
    cCelltypeInfo_set_descriptor( CTdesc );
    cCelltypeInfo_getName( VAR_celltype_path, ATTR_NAME_LEN );
    n = cCelltypeInfo_getNEntry();

    for( i = 0; i < n; i++ ){
      if( VAR_find_entry ){
        break;
      }
      cCelltypeInfo_getEntryInfo( i, &entryDesc);
      print_entry( p_cellcb, entryDesc );
    }
}

static void
print_entry(CELLCB  *p_cellcb, Descriptor( nTECSInfo_sEntryInfo )  Edesc )
{
    Descriptor( nTECSInfo_sSignatureInfo ) sigDesc;
    cEntryInfo_set_descriptor( Edesc );
    cEntryInfo_getName(VAR_entry_path, ATTR_NAME_LEN);
    if( !strcmp(VAR_entry_path, VAR_entry_path_tmp ) ){
      // sprintf( VAR_entry_path, "%s.%s", VAR_cell_path, VAR_entry_path_tmp );
      VAR_find_entry = 1;
      cEntryInfo_getSignatureInfo( &sigDesc );
      print_signature( p_cellcb, sigDesc );
    }else{
      strcpy( VAR_entry_path, "" );
    }
}

static void
print_signature( CELLCB *p_cellcb, Descriptor( nTECSInfo_sSignatureInfo )  signatureDesc )
{
    int n, i;
    Descriptor( nTECSInfo_sFunctionInfo )  functionDesc;
    /* signatureInfoセルに動的結合 */
    cSignatureInfo_set_descriptor( signatureDesc );
    cSignatureInfo_getName( VAR_signature_path, ATTR_NAME_LEN );
    n = cSignatureInfo_getNFunction();
    for(i = 0; i < n; i++){
        if( VAR_find_func ){
            break;
        }
        cSignatureInfo_getFunctionInfo(i, &functionDesc);
        print_function( p_cellcb, functionDesc );
    }
}

static void
print_function( CELLCB *p_cellcb, Descriptor( nTECSInfo_sFunctionInfo ) functionDesc )
{
    int i;
    Descriptor( nTECSInfo_sParamInfo ) paramInfo;
    Descriptor( nTECSInfo_sTypeInfo ) typeInfo;

    cFunctionInfo_set_descriptor( functionDesc );
    cFunctionInfo_getName( VAR_function_path, ATTR_NAME_LEN );

    if( !strcmp( VAR_function_path, VAR_function_path_tmp ) ){
      VAR_find_func = 1;
      VAR_arg_num = cFunctionInfo_getNParam();
      cFunctionInfo_getReturnTypeInfo( &typeInfo );
      cTypeInfo_set_descriptor( typeInfo );
      cTypeInfo_getName( VAR_exp_type, ATTR_ARG_NAME_LEN );
      for(i = 0; i < VAR_arg_num; i++){
          cFunctionInfo_getParamInfo(i, &paramInfo);
          print_param( p_cellcb, paramInfo, i );
      }
    }else{
      strcpy( VAR_function_path, "" );
      return;
    }
}

static void
print_param( CELLCB *p_cellcb, Descriptor( nTECSInfo_sParamInfo ) paramDesc, int num )
{
    int n, i;
    char_t tmp[8];
    Descriptor( nTECSInfo_sTypeInfo ) typeInfo;
    Descriptor( nTECSInfo_sVarDeclInfo ) memberInfo;

    cParamInfo_set_descriptor( paramDesc );
    cParamInfo_getName( VAR_arg[num], ATTR_ARG_NAME_LEN );
    // printf("%s\n",VAR_arg[num]);
    cParamInfo_getTypeInfo( &typeInfo );
    cTypeInfo_set_descriptor( typeInfo );
    cTypeInfo_getName( VAR_arg_type[num], ATTR_ARG_NAME_LEN );
    // printf("%s\n",VAR_arg_type[num]);

    // TODO
    // if( strstr( VAR_arg_type[num], "struct") != NULL ){
    //     // n = 0;
    //     n = cTypeInfo_getNMember();
    //     printf("%d\n",n);

    //     // for(i = 0; i < n; i++){
    //     //     cTypeInfo_getMemberInfo( i, &memberInfo );
    //     //     cVarDeclInfo_set_descriptor( memberInfo );
    //     //     cVarDeclInfo_getName( tmp, 8 );
    //     //     printf("%s\n",tmp);
    //     // }
    // }

}

int
isNull( const char *str)
{
    if( str == NULL || !strlen(str) ){
      return true;
    }
    return false;
};
