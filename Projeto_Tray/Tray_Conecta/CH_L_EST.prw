#Include "Totvs.ch"

/*/{Protheus.doc} CH_L_PRDEMP
@author Ihorran Milholi
@since 17/05/2021
@version 1.0
/*/

/*
CAMPOS PARA RETORNO DA QUERY
CODIGO
NOME

*/

User Function CH_L_EST(nParamDias)

	Local cQuery := ""

	cQuery += " SELECT"
	cQuery += " 	SB1.B1_COD              						PRODUTO,"
	cQuery += " 	" + ValToSql(cEmpAnt) + " + SB2.B2_FILIAL    	EMPRESA_SIGLA,"
	cQuery += " 	NNR.NNR_CODIGO          						LOCAL,"
	cQuery += "		ISNULL(SB2.B2_CM1,0)    						CUSTO,"
	cQuery += "		(ISNULL(SB2.B2_QATU,0) - ISNULL(SB2.B2_RESERVA,0)) ESTOQUEATUAL,"

	cQuery += "		row_number() over (order by SB1.B1_FILIAL, SB1.B1_COD, NNR.NNR_CODIGO) linha_tabela"

	cQuery += " FROM "+RetSqlName("SB1")+" SB1"

	cQuery += " INNER JOIN "+RetSqlName("NNR")+" NNR ON "
	cQuery += "     NNR.NNR_FILIAL  = " + ValToSql(xFilial("NNR"))
	cQuery += " AND NNR.NNR_CODIGO IN " + FormatIn(GetNewPar("MV_XTREST", "P3"), ";")
	cQuery += " AND NNR.D_E_L_E_T_  = ''"

	cQuery += " INNER JOIN "+RetSqlName("SB2")+" SB2 ON "
	cQuery += "     SB2.B2_FILIAL   = '03'"
	cQuery += " AND SB2.B2_COD      = SB1.B1_COD"
	cQuery += " AND SB2.B2_LOCAL    = NNR.NNR_CODIGO"
	cQuery += " AND SB2.D_E_L_E_T_  = ''"

	// cQuery += " INNER JOIN "+RetSqlName("ACV")+" ACV ON "
	// cQuery += "     ACV.ACV_FILIAL  = " + ValToSql(xFilial("ACV"))
	// cQuery += " AND ACV.ACV_CODPRO  = SB1.B1_COD"
	// cQuery += " AND ACV.D_E_L_E_T_  = ''"

	// cQuery += " INNER JOIN "+RetSqlName("ACU")+" ACU ON "
	// cQuery += "     ACU.ACU_FILIAL  = " + ValToSql(xFilial("ACU"))
	// cQuery += " AND ACU.ACU_COD     = ACV.ACV_CATEGO "
	// cQuery += " AND ACU.D_E_L_E_T_  = ''"

	cQuery += " WHERE"
	cQuery += "     SB1.B1_FILIAL   = '"+xFilial("SB1")+"'"
	cQuery += " AND SB1.D_E_L_E_T_  = ''"

Return cQuery
