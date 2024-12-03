/*/{Protheus.doc} CH_L_TRA
@author Ihorran Milholi
@since 17/05/2021
@version 1.0
/*/

/*
CAMPOS PARA RETORNO DA QUERY
NOME
CNPJ
FANTASIA
INSCRICAOESTADUAL
ENDERECO
BAIRRO
NUMERO
COMPLEMENTO
CEP
CIDADE
ESTADO
FONE
FAX
EMAIL

*/

User Function CH_L_TRA(nParamDias)

	Local cQuery := ""

	cQuery += " SELECT"
	cQuery += "     SA4.A4_COD  CODIGO,"
	cQuery += "     SA4.A4_NOME NOME,"
	cQuery += "     SA4.A4_CGC  CNPJ,"
	cQuery += "     CASE WHEN SA4.A4_NREDUZ = '' THEN SA4.A4_NOME ELSE SA4.A4_NREDUZ END FANTASIA,"
	cQuery += "     SA4.A4_INSEST as INSCRICAOESTADUAL,"
	cQuery += "     SA4.A4_END ENDERECO,"
	cQuery += "     SA4.A4_BAIRRO BAIRRO,"
	cQuery += "     SA4.A4_CEP CEP,"
	cQuery += "     SA4.A4_MUN CIDADE,"
	cQuery += "     SA4.A4_EST ESTADO,"
	cQuery += "     SA4.A4_COMPLEM COMPLEMENTO,"
	cQuery += "     SA4.A4_TEL FONE,"
	cQuery += "     row_number() over (order by SA4.A4_FILIAL, SA4.A4_COD) linha_tabela"

	cQuery += " FROM "+RetSqlName("SA4")+" (NOLOCK) SA4"

	cQuery += " WHERE"
	cQuery += "     SA4.A4_FILIAL   = " + ValToSql(xFilial("SA4"))
	cQuery += " AND SA4.A4_XINTTRA  = " + ValToSql("1")
	cQuery += " AND	SA4.D_E_L_E_T_  = ''"

Return cQuery
