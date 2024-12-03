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

User Function CH_L_PRC(nParamDias)

	Local cQuery := ""

	cQuery += " SELECT"
	cQuery += " 	SB1.B1_COD                  PRODUTO,"
	cQuery += " 	" + ValToSql(cEmpAnt) + " + " + ValToSql("03") + "    	EMPRESA_SIGLA,"
	cQuery += "		" + ValToSql("001") + "     TABELAPRECO,"
	cQuery += "		ISNULL(DA1.DA1_PRCVEN,0)    PRECO,"

	cQuery += "		row_number() over (order by SB1.B1_FILIAL, SB1.B1_COD, DA1.DA1_CODTAB) linha_tabela"

	cQuery += " FROM "+RetSqlName("SB1")+" SB1"

	cQuery += " INNER JOIN "+RetSqlName("DA1")+" DA1 ON "
	cQuery += "     DA1.DA1_FILIAL  = " + ValToSql(xFilial("DA1"))
	cQuery += " AND DA1.DA1_CODPRO  = SB1.B1_COD"
	cQuery += " AND DA1.DA1_CODTAB  IN " + FormatIn(GetNewPar("MV_XTBPTRA", "159"), ";")
	cQuery += " AND DA1.D_E_L_E_T_  = ''"

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
