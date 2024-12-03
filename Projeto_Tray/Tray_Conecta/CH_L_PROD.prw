#Include "Totvs.ch"

/*/{Protheus.doc} CH_L_PROD
@author Ihorran Milholi
@since 17/05/2021
@version 1.0

/*/

User Function CH_L_PROD(nParamDias)

	Local cQuery := ""

	cQuery += " SELECT"
	cQuery += "     SB1.B1_COD          CODIGO,"
	cQuery += "     SB1.B1_COD          CODIGOERP,"
	cQuery += "     CASE WHEN ISNULL(SB5.B5_ECTITU,'') = '' THEN SB1.B1_DESC ELSE SB5.B5_ECTITU END NOME,"
	cQuery += "     'Prodiet'			MARCA,"
	cQuery += "     SB1.B1_POSIPI       NCM,"
	cQuery += "     SB1.B1_CODBAR       CODIGOUNIVERSAL,"
	cQuery += "     SB1.B1_ORIGEM       ORIGEM,"
	cQuery += "     SB1.B1_GRUPO        CATEGORIA,"
	cQuery += "     ISNULL(SB1.B1_PESO,0)       PESO,"
	cQuery += "     ISNULL(SB5.B5_LARG,0)    	LARGURA,"
	cQuery += "     ISNULL(SB5.B5_COMPR,0)     	PROFUNDIDADE,"
	cQuery += "     ISNULL(SB5.B5_ALTURA,0)    	ALTURA,"
	// cQuery += "     ISNULL(SB5.B5_QE1,0)    	EMBALAGEM,"
	cQuery += "     0					    	EMBALAGEM,"
	cQuery += "     CASE WHEN SB1.B1_MSBLQL IN ('2', '') AND B5_XECOM IN " + FormatIn(GetNewPar("MV_XINTRAY", "2"), ";") + " THEN 'ativo' ELSE 'inativo' END STATUS,"
	cQuery += "     row_number() over (order by SB1.B1_FILIAL, SB1.B1_COD) linha_tabela"

	cQuery += " FROM "+ RetSqlName("SB1")+" SB1 "

	cQuery += " INNER JOIN "+RetSqlName("SB5")+" SB5 ON "
	cQuery += "     SB5.B5_FILIAL   = " + ValToSql(xFilial("SB5"))
	cQuery += " AND SB5.B5_COD      = SB1.B1_COD"
	// cQuery += " AND SB5.B5_XECOM    IN " + FormatIn(GetNewPar("MV_XINTRAY", "2"), ";")
	cQuery += " AND SB5.D_E_L_E_T_  = ''"

	// cQuery += " INNER JOIN "+RetSqlName("ACV")+" ACV ON "
	// cQuery += "     ACV.ACV_FILIAL  = " + ValToSql(xFilial("ACV"))
	// cQuery += " AND ACV.ACV_CODPRO  = SB1.B1_COD"
	// cQuery += " AND ACV.D_E_L_E_T_  = ''"

	// cQuery += " INNER JOIN "+RetSqlName("ACU")+" ACU ON "
	// cQuery += "     ACU.ACU_FILIAL  = " + ValToSql(xFilial("ACU"))
	// cQuery += " AND ACU.ACU_COD     = ACV.ACV_CATEGO "
	// cQuery += " AND ACU.D_E_L_E_T_  = ''"

	cQuery += " WHERE"
	cQuery += "     SB1.B1_FILIAL   = " + ValToSql(xFilial("SB1"))
	cQuery += " AND SB1.B1_TIPO		= 'PA'"
	cQuery += " AND SB1.D_E_L_E_T_  = ''"

Return cQuery
