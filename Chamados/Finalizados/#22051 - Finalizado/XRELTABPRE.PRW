#Include 'Protheus.ch'
#INCLUDE 'TOPCONN.CH'
#include "TBICONN.ch"
#include "rwmake.ch"
/*__________________________________________________________________________
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¦¦+-----------------------------------------------------------------------+¦¦
¦¦¦Funçäo    ¦ xRelCusD2¦ Autor ¦                      ¦ Data ¦           ¦¦¦
¦¦+----------+------------------------------------------------------------¦¦¦
¦¦¦Descriçäo ¦ Relatório para impressão dos alternativo          ¦¦
¦¦¦          ¦                                                             ¦¦
¦¦+-----------------------------------------------------------------------+¦¦
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯*/
User Function xRelTabPr()

Local cPerg         := Padr("XRELTABPR",10)
	/*//Cria perguntas
	u_zPutSX1(cPerg, "01", "Produto De?",   "MV_PAR01", "MV_CH0", "C", TamSX3('B1_COD')[01], 0,    "G", , "SB1", "@!", , , , , , "Informe o produto inicial")
    u_zPutSX1(cPerg, "02", "Produto Até?",  "MV_PAR02", "MV_CH1", "C", TamSX3('B1_COD')[01], 0,    "G", , "SB1", "@!", , , , , , "Informe o produto final")
    u_zPutSX1(cPerg, "03", "Vigência De?",  "MV_PAR03", "MV_CH2", "D", TamSX3('AIA_DATDE')[01], 0, "G", ,      ,     , , , , , , "Informe a Data inicial")
    u_zPutSX1(cPerg, "04", "Vigência Até?", "MV_PAR04", "MV_CH3", "D", TamSX3('AIA_DATDE')[01], 0, "G", ,      ,     , , , , , , "Informe a Data final")
*/
//Abre pergunta
Pergunte(cPerg,.T.)

//Variaveis

cProdDe     := AllTrim(MV_PAR01)
cProdAte    := AllTrim(MV_PAR02)
cDataDe     := DTOS(MV_PAR03)
cDataAte    := DTOS(MV_PAR04)
nPeriodos   := DateDiffMonth(MV_PAR03,MV_PAR04)

Processa( {|| MontaDados( cProdDe, cProdAte, cDataDe, cDataAte, nPeriodos )}, "Aguarde...", "Gerando dados relatório de Preço...",.F.)

Return

Static Function MontaDados()

	Local aPreco        :=  {}
	Local aArea         := GetArea()
	Local cArquivo      := GetTempPath()+'TabelaPreco.xml'
	Local cQuery        := ""
	Local cDataVal      := ""
	Local nX            := 0
	Local nMaxPreco     := 0
	Local oFWMsExcel
	Local oExcel

	//ConOut("xRelTabPre - Monta query para pegar dados.")
	FWLogMsg("INFO", /*cTransactionId*/, "Compras", "xRelTabPre", /*cStep*/, /*cMsgId*/, "Monta query para pegar dados.", /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	cQuery := " SELECT "
	cQuery += " AIB_FILIAL FILIAL, "
	cQuery += " AIB_CODFOR COD_FORNECEDOR, "
	cQuery += " AIB_LOJFOR LOJA_FORNECEDOR, "
	cQuery += " A2.A2_MUN MUNICIPIO, "
	cQuery += " A2.A2_EST ESTADO, "
	cQuery += " A2.A2_NOME RAZAO_SOCIAL, "
	cQuery += " AIB_CODTAB COD_TABELA, "
//	cQuery += " AIA_DESCRI DESC_TABELA, "
//	cQuery += " AIB_ITEM ITEM, "
	cQuery += " AIB_CODPRO COD_PRODUTO, "
	cQuery += " B1_DESC DESC_PRODUTO, "
	cQuery += " B1_PROC COD_PROD_FOR, "
//	cQuery += " AIB_PRCCOM PRECO, "
	cQuery += " AIB_INDLOT LOTE_PRECO,"
	cQuery += " CASE AIB_MOEDA WHEN '1' THEN 'REAL' WHEN '2' THEN 'DOLAR' WHEN '3' THEN 'UF' WHEN '4' THEN 'EURO' Else 'OUTRAS' End AS MOEDA,"
//	cQuery += " AIB_DATVIG VIGENCIA_PRECO,"
//	cQuery += " AIA_DATDE VALIDADE_TAB_DE,"
	cQuery += " AIA_DATATE VALIDADE_TAB_ATE,"
//	cQuery += " E4_DESCRI CONDICAO_PAGAMENTO,"
	cQuery += " B1_GRUPO COD_GRUPO,"
	cQuery += " B1_DESCGRU DESC_GRUPO,"
	cQuery += " B1_TIPO TIPO_PRODUTO,"
	cQuery += " X5ORI.X5_DESCRI ORIGEM,"
	cQuery += " B1_UM UNIDADE_MEDIDA,"
	cQuery += " CASE B1_LIQUIDO WHEN '1' THEN 'LIQUÍDO' WHEN '2' THEN 'PÓ' Else 'OUTROS' End AS APRESENTACAO,"
	cQuery += " B1_QE QUANTIDADE_EMBALAGEM, "
	cQuery += " B1_POSIPI NCM,"
	cQuery += " B1_LM LOTE_MINIMO, "
	cQuery += " CASE B1_TIPE WHEN 'D' THEN 'DIAS' WHEN 'M' THEN 'MESES' Else 'NAO INFORMADO' End AS TIPO_PRAZO, "
	cQuery += " B1_PE PRAZO, "
	cQuery += " B1_PCOFINS COFINS, "
	cQuery += " B1_PPIS PIS, "
	cQuery += " B1_XPERIMP PERCIMPORTA, "
	cQuery += " B1_XORIGEM ORIGEMCOMPRA, "
	cQuery += " CASE B1_MSBLQL WHEN '1' THEN 'BLOQUEADO' WHEN '2' THEN 'LIBERADO' Else 'LIBERADO' End AS BLOQUEADO "
	// cQuery += " AIB_XOBS OBS_ITEM " //Adicionado por Leonardo - 04.05.2022
	cQuery += " FROM "+RetSqlName("AIB")+" (nolock) B "
	cQuery += " INNER JOIN "+RetSqlName("AIA")+" (nolock) A ON A.AIA_FILIAL = B.AIB_FILIAL AND A.AIA_CODFOR = B.AIB_CODFOR AND A.AIA_CODTAB = B.AIB_CODTAB AND A.AIA_LOJFOR = B.AIB_LOJFOR "
	cQuery += " INNER JOIN "+RetSqlName("SB1")+" (nolock) B1 ON B1.B1_COD = B.AIB_CODPRO  "
	cQuery += " INNER JOIN "+RetSqlName("SA2")+" (nolock) A2 ON A2.A2_COD = B.AIB_CODFOR AND A2.A2_LOJA = B.AIB_LOJFOR "
	//cQuery += " LEFT JOIN  "+RetSqlName("SE4")+" (nolock) E4 ON E4.E4_CODIGO = A.AIA_CONDPG  " // Centro de custo não é mais informado
	cQuery += " LEFT JOIN  "+RetSqlName("SX5")+" (nolock) X5ORI ON X5ORI.X5_TABELA = 'S0' AND X5ORI.X5_CHAVE = B1.B1_ORIGEM "
	cQuery += " WHERE "
	cQuery += " B1.B1_COD BETWEEN '"+cProdDe+"' AND '"+cProdAte+"' AND "
	//cQuery += " A.AIA_DATDE     >= '"+cDataDe+"' AND A.AIA_DATATE <= '"+cDataAte+"' "
	cQuery += " A.D_E_L_E_T_     = '' AND "
	cQuery += " B.D_E_L_E_T_     = '' AND "
	cQuery += " B1.D_E_L_E_T_    = '' AND "
	cQuery += " A2.D_E_L_E_T_    = '' AND "
	//cQuery += " E4.D_E_L_E_T_    = '' AND "
	cQuery += " X5ORI.D_E_L_E_T_ = '' "
	cQuery += " GROUP BY AIB_FILIAL, AIB_CODFOR, AIB_LOJFOR, A2_MUN, A2_EST, A2_NOME, AIB_CODPRO, B1_DESC, B1_PROC, AIB_INDLOT, AIB_MOEDA, B1_GRUPO, B1_DESCGRU, B1_TIPO, X5_DESCRI, B1_UM, B1_LIQUIDO, B1_POSIPI, B1_QE, B1_LM, B1_TIPE, B1_PE, B1_PCOFINS, B1_PPIS, B1_MSBLQL, B1_XPERIMP, B1_XORIGEM,AIB_CODTAB,AIA_DATATE " //, AIB_XOBS   "
	cQuery += " ORDER BY AIB_FILIAL, AIB_CODPRO, AIB_CODFOR "

	TCQuery cQuery New Alias "QRYPRO"

	//ConOut("xRelTabPre - Criando o objeto que irá gerar o conteúdo do Excel.")
	FWLogMsg("INFO", /*cTransactionId*/, "Compras", "xRelTabPre", /*cStep*/, /*cMsgId*/, "Criando o objeto que irá gerar o conteúdo do Excel.", /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	//Criando o objeto que irá gerar o conteúdo do Excel
	oFWMsExcel := FWMSExcel():New()

	//ConOut("xRelTabPre - Criando planilha (01 - Preços).")
	FWLogMsg("INFO", /*cTransactionId*/, "Compras", "xRelTabPre", /*cStep*/, /*cMsgId*/, "Criando planilha (01 - Preços).", /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	//Aba 01 - Produtos
	oFWMsExcel:AddworkSheet("PRECOS")
	//ConOut("xRelTabPre - Criando tabela.")
	FWLogMsg("INFO", /*cTransactionId*/, "Compras", "xRelTabPre", /*cStep*/, /*cMsgId*/, "Criando tabela.", /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	//Criando a Tabela
	oFWMsExcel:AddTable("PRECOS","Dados")
	//ConOut("xRelTabPre - Criando colunas.")
	FWLogMsg("INFO", /*cTransactionId*/, "Compras", "xRelTabPre", /*cStep*/, /*cMsgId*/, "Criando colunas.", /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	oFWMsExcel:AddColumn("PRECOS","Dados","Filial",1) //1
	//oFWMsExcel:AddColumn("PRECOS","Dados","Cód. Tabela",1) //2
	//oFWMsExcel:AddColumn("PRECOS","Dados","Desc. Tabela",1) //3
	//oFWMsExcel:AddColumn("PRECOS","Dados","Dt. DE Vigência Tabela",1) //4
	//oFWMsExcel:AddColumn("PRECOS","Dados","Dt. ATE Vigência Tabela",1) //5
	//oFWMsExcel:AddColumn("PRECOS","Dados","Item Tabela",1) //6
	oFWMsExcel:AddColumn("PRECOS","Dados","Cód. Produto",1) //7
	oFWMsExcel:AddColumn("PRECOS","Dados","Desc. Produto",1) //8
	oFWMsExcel:AddColumn("PRECOS","Dados","Cód. Grupo Produto",1) //9
	oFWMsExcel:AddColumn("PRECOS","Dados","Desc. Grupo Produto",1) //10
	oFWMsExcel:AddColumn("PRECOS","Dados","Tipo Produto",1) //11
	oFWMsExcel:AddColumn("PRECOS","Dados","Cód. Produto Fornecedor",1) //12
	oFWMsExcel:AddColumn("PRECOS","Dados","Status",1) //13
	oFWMsExcel:AddColumn("PRECOS","Dados","Razão Social",1) //14
	oFWMsExcel:AddColumn("PRECOS","Dados","Origem",1) //15
	oFWMsExcel:AddColumn("PRECOS","Dados","Município",1) //16
	oFWMsExcel:AddColumn("PRECOS","Dados","Estado",1) //17
	//oFWMsExcel:AddColumn("PRECOS","Dados","Cód. Fornecedor",1) //1
	//oFWMsExcel:AddColumn("PRECOS","Dados","Loja Fornecedor",1) //1
	oFWMsExcel:AddColumn("PRECOS","Dados","Unidade de Medida",1) //18
	//oFWMsExcel:AddColumn("PRECOS","Dados","Apresentação",1) //19
	oFWMsExcel:AddColumn("PRECOS","Dados","Embalagem Unitária",1) //20
	oFWMsExcel:AddColumn("PRECOS","Dados","Lote Mínimo de Compra",1) //21
	oFWMsExcel:AddColumn("PRECOS","Dados","LeadTime",1) //22
	oFWMsExcel:AddColumn("PRECOS","Dados","NCM",1) //23
	oFWMsExcel:AddColumn("PRECOS","Dados","Prazo de Pagamento",1) //24
	oFWMsExcel:AddColumn("PRECOS","Dados","ICMS",1) //25
	oFWMsExcel:AddColumn("PRECOS","Dados","IPI",1) //26
	oFWMsExcel:AddColumn("PRECOS","Dados","Pis",1) //27
	oFWMsExcel:AddColumn("PRECOS","Dados","Cofins",1) //28
	oFWMsExcel:AddColumn("PRECOS","Dados","II",1) //29
	oFWMsExcel:AddColumn("PRECOS","Dados","Coeficiente de Impostos ",1) //30
	oFWMsExcel:AddColumn("PRECOS","Dados","Importação Direta",1) //31
	oFWMsExcel:AddColumn("PRECOS","Dados","Moeda",1) //32
	oFWMsExcel:AddColumn("PRECOS","Dados","Lote de Compra Até",1) //33
	oFWMsExcel:AddColumn("PRECOS","Dados","Inf. da TES",1) //33
	//oFWMsExcel:AddColumn("PRECOS","Dados","Dt. Vigência Preço",1) //34
	//oFWMsExcel:AddColumn("PRECOS","Dados","Preço",1) //1
	oFWMsExcel:AddColumn("PRECOS","Dados","Obs. item",1) //Adicionado por Leonardo - 04.05.2022
	//ULTIMO PREÇO CADASTRADO
	For nX := 0 to nPeriodos
		//ConOut("xRelTabPre - Criando coluna de período "+ cValToChar(nX) +".")
		FWLogMsg("INFO", /*cTransactionId*/, "Compras", "xRelTabPre", cValToChar(nX), /*cMsgId*/, "Criando coluna de período "+ cValToChar(nX) +".", /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		cDataRel := DTOS(MonthSum(MV_PAR03,nX))
		cDataCol := Substr(cDataRel,5,2) + "-" + Substr(cDataRel,1,4)
		oFWMsExcel:AddColumn("PRECOS","Dados",cDataCol,1) //1
	Next nX

	oFWMsExcel:AddColumn("PRECOS","Dados","Preço Reposição",1) //penultimo
	oFWMsExcel:AddColumn("PRECOS","Dados","Custo Controladoria",1) //ultimo

	ProcRegua(1000)
	//Criando as Linhas... Enquanto não for fim da query
	//ConOut("xRelTabPre - Alimentando variáveis para montas as linhas.")
	FWLogMsg("INFO", /*cTransactionId*/, "Compras", "xRelTabPre", /*cStep*/, /*cMsgId*/, "Alimentando variáveis para montas as linhas.", /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	While !(QRYPRO->(EoF()))

		If STOD(QRYPRO->VALIDADE_TAB_ATE) >= MV_PAR03
			IncProc("Verificando Preços:"+QRYPRO->DESC_PRODUTO)
			//Atribui Valores
			cFilTab     := QRYPRO->FILIAL
			cCodFor     := QRYPRO->COD_FORNECEDOR
			cLojaFor    := QRYPRO->LOJA_FORNECEDOR
			cMun        := AllTrim(QRYPRO->MUNICIPIO)
			cEst        := QRYPRO->ESTADO
			cRazao      := AllTrim(QRYPRO->RAZAO_SOCIAL)
			cCodTab     := QRYPRO->COD_TABELA
			//  cDescTab    := AllTrim(QRYPRO->DESC_TABELA)
			//  cItem       := QRYPRO->ITEM
			cCodPro     := QRYPRO->COD_PRODUTO
			cDescPro    := QRYPRO->DESC_PRODUTO
			cTipoPro    := QRYPRO->TIPO_PRODUTO
			cCodProFr   := QRYPRO->COD_PROD_FOR
			//  nPreco      := QRYPRO->PRECO
			cLotePreco  := QRYPRO->LOTE_PRECO
			cMoeda      := QRYPRO->MOEDA
			//   dDtVigencia := STOD(QRYPRO->VIGENCIA_PRECO)
			//  dDtTabDe    := STOD(QRYPRO->VALIDADE_TAB_DE)
			//  dDtTabAte   := STOD(QRYPRO->VALIDADE_TAB_ATE)
			cCodPag     := ""//AllTrim(QRYPRO->CONDICAO_PAGAMENTO)
			cCodGrupo   := QRYPRO->COD_GRUPO
			cDescGrupo  := AllTrim(QRYPRO->DESC_GRUPO)
			cOrigem     := AllTrim(QRYPRO->ORIGEM)
			cUNMed      := AllTrim(QRYPRO->UNIDADE_MEDIDA)
			cOrigemCom  := If(AllTrim(QRYPRO->ORIGEMCOMPRA)=="1","Importado","Nacional")
			nQE         := QRYPRO->QUANTIDADE_EMBALAGEM
			cNCM        := AllTrim(QRYPRO->NCM)
			nLM         := QRYPRO->LOTE_MINIMO
			cTipoPrazo  := AllTrim(QRYPRO->TIPO_PRAZO)
			cPrazo      := cValToChar(QRYPRO->PRAZO)
			cStatus     := QRYPRO->BLOQUEADO
			aImpProd    := getImp(cCodPro,cCodFor,cLojaFor,cDataDe,cDataAte)
			nMedPag     := 0//getMedPag()
			nICMS       := iif(Len(aImpProd)>0,aImpProd[1][2],0)
			nIPI        := iif(Len(aImpProd)>0,aImpProd[1][3],0)
			nCofins     := iif(Len(aImpProd)>0,aImpProd[1][4],0)
			nPIS        := iif(Len(aImpProd)>0,aImpProd[1][5],0)
			cDescTes    := iif(Len(aImpProd)>0,aImpProd[1][6],0)
			cObsItem    := getMsg(cCodPro,cCodFor,cLojaFor) //QRYPRO->OBS_ITEM //Adicionado por Leonardo - 04.05.2022
			nII         := QRYPRO->PERCIMPORTA//QRYPRO->II
			If cOrigemCom == "Importado"
				nTotImp     := 1-(nII/100)
				nICMS       := 0
				nIPI        := 0
				nCofins     := 0
				nPIS        := 0
			Else
				nTotImp     := 1-((nICMS + nCofins + nPIS)/100)
			EndIf
			nSoma       := 0//soma dos preços, para verificar se imprime linha
			nMaxPreco   := 0
			//ConOut("xRelTabPre - Alimenta array aCab.")
			FWLogMsg("INFO", /*cTransactionId*/, "Compras", "xRelTabPre", /*cStep*/, /*cMsgId*/, "Alimenta array aCab.", /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
			aCab        := {;
				cFilTab,;
				cCodPro,;
				cDescPro,;
				cCodGrupo,;
				cDescGrupo,;
				cTipoPro,;
				cCodProFr,;
				cStatus,;
				cRazao,;
				cOrigem,;
				cMun ,;
				cEst,;
				cUNMed,;
				nQE,;
				nLM,;
				cPrazo + " " + cTipoPrazo,;
				cNCM,;
				cCodPag,;
				nICMS,;//icms
			nIPI,;//ipi
			nPIS,;
				nCofins,;
				nII,;//ii
			nTotImp,;//total de impostos
			cOrigemCom,;
				cMoeda,;
				cLotePreco,;
				cDescTes,;
				cObsItem; //Adicionado por Leonardo - 04.05.2022
			}
			//ConOut("xRelTabPre - Alimentando preços.")
			FWLogMsg("INFO", /*cTransactionId*/, "Compras", "xRelTabPre", /*cStep*/, /*cMsgId*/, "Alimentando preços.", /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
			//Adiciona Preços
			For nX := 0 to nPeriodos
				cDataRel    := DTOS(MonthSum(MV_PAR03,nX)) //Primeira passada na variavel.
				aPreco  :=  {}
				aPreco      := getPreco(cCodPro,cCodFor,cLojaFor,cDataRel,cLotePreco,cMoeda,cCodTab)
				nPreco      := aPreco[1][1]
				cDataVal    := aPreco[1][2]
				nSoma       += nPreco // verifica se tem valor de preço no período setado
				If nPreco > 0
					If nX == 0 //se é a primeira passada, carrega o valor
						nMaxPreco := nPreco
					elseif STOD(cDataRel) < STOD(cDataVal) //proximas passadas do nx, verifica se a data do preço é menor que a atual
						nMaxPreco := nPreco
					EndIf
				EndIf
				aaDD(aCab,Round(nPreco,2))
			Next nX
			If nSoma > 0
				aaDD(aCab,Round(nMaxPreco,2))//Preço Reposição
				If cOrigemCom == "Importado"
					aaDD(aCab,Round(nMaxPreco+(nMaxPreco*(nII/100)),2))//Preço controladoria
				Else
					aaDD(aCab,Round(nMaxPreco*nTotImp,2))//Preço controladoria
				EndIf
				oFWMsExcel:AddRow("PRECOS","Dados",aCab)//imprime linha
			EndIf
			//Pulando Registro
			QRYPRO->(DbSkip())
		Else
			QRYPRO->(DbSkip()) // se tabela nao vigente
		EndIf
	EndDo
	//ConOut("xRelTabPre - Ativando excel.")
	FWLogMsg("INFO", /*cTransactionId*/, "Compras", "xRelTabPre", /*cStep*/, /*cMsgId*/, "Ativando excel.", /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	//Ativando o arquivo e gerando o xml
	oFWMsExcel:Activate()
	oFWMsExcel:GetXMLFile(cArquivo)

	//Abrindo o excel e abrindo o arquivo xml
	oExcel := MsExcel():New()             //Abre uma nova conexão com Excel
	oExcel:WorkBooks:Open(cArquivo)     //Abre uma planilha
	oExcel:SetVisible(.T.)                 //Visualiza a planilha
	oExcel:Destroy()                        //Encerra o processo do gerenciador de tarefas

	QRYPRO->(DbCloseArea())
	RestArea(aArea)

Return


Static Function getImp(cProduto,cCodFor,cLojaFor,cDataDe,cDataAte)

	Local aDados    := {}
	Local cQry      := ""
	Local nAlqICM   := 0

//ConOut("xRelTabPre - Monta query para getImp.")
	FWLogMsg("INFO", /*cTransactionId*/, "Compras", "xRelTabPre", /*cStep*/, /*cMsgId*/, "Monta query para getImp.", /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	cQry += " SELECT "
	cQry += " SUBSTRING(D1.D1_DTDIGIT,1,6)+'01' AS DT_ENTRADA, "
	cQry += " D1_VALICM AS VAL_ICMS,"
	cQry += " D1_BASEICM AS BASE_ICMS,"
	cQry += " D1_IPI AS ALQ_IPI, "
	cQry += " D1_ALQIMP5 AS ALQ_COFINS,"
	cQry += " F4_FINALID AS TEXTO, "
	cQry += " D1_ALQIMP6 AS ALQ_PIS, "
	cQry += " F4_PICMDIF AS ALQ_DIF, "
	cQry += " D1_TOTAL AS TOTAL_LINHA " //ADD JONATAS 20230324
	cQry += " FROM "+RetSqlName("SD1")+" D1  "
	cQry += " INNER JOIN "+RetSqlName("SF4")+" F4 ON D1_FILIAL = F4_FILIAL AND D1_TES = F4_CODIGO AND F4.D_E_L_E_T_ ='' "
	cQry += " WHERE "
	cQry += " D1.D1_FORNECE = '"+cCodFor+"' AND "
	cQry += " D1.D1_LOJA    = '"+cLojaFor+"' AND "
	cQry += " D1.D1_COD     = '"+cProduto+"' AND "
	cQry += " D1.D1_QUANT   > 0 AND "
//cQry += " D1.D1_DTDIGIT >= '"+cDataAte+"' AND  "
	cQry += " SUBSTRING(D1.D1_CF,2,3) = '101' AND "
	cQry += " D1.D_E_L_E_T_ = '' "
	cQry += " ORDER BY  SUBSTRING(D1.D1_DTDIGIT,1,6) DESC "

	If Select("QRYPROD") <> 0
		DbSelectArea("QRYPROD")
		DbCloseArea()
	EndIf

	TCQuery cQry New Alias "QRYPROD"

	While QRYPROD->(!EoF()) .and. Len(aDados) < 1
		If QRYPROD->VAL_ICMS > 0
			nAlqICM := Round((QRYPROD->VAL_ICMS/QRYPROD->TOTAL_LINHA)*100,0)//ADD JONATAS 20230324
			//   nAlqICM := Round((QRYPROD->VAL_ICMS/QRYPROD->BASE_ICMS)*100,0)//COMENTADO JONATAS 20230324
			//      If QRYPROD->ALQ_DIF < 100
			//        nAlqICM :=  Round(nAlqICM * (QRYPROD->ALQ_DIF/100),0)
			//    EndIf
		Else
			nAlqICM := 0
		EndIf
		aaDD(aDados,{QRYPROD->DT_ENTRADA,nAlqICM,QRYPROD->ALQ_IPI,QRYPROD->ALQ_COFINS,QRYPROD->ALQ_PIS,QRYPROD->TEXTO})
		QRYPROD->(DbSkip())
	End

	QRYPROD->(DbCloseArea())
Return aDados


Static Function getPreco(cProduto,cCodFor,cLojaFor,cDataDe,cLotePreco,cMoeda,cCodTab)

	Local aPreco := {}
	Local cQry   := ""
	Local cMD    := ""
	Local cMoeda1 := AllTrim(cMoeda)

	Do Case
	Case cMoeda1 == "REAL"
		cMD := "1"
	Case cMoeda1 == "DOLAR"
		cMD := "2"
	Case cMoeda1 == "UF"
		cMD := "3"
	Case cMoeda == "EURO"
		cMD := "4"
	OtherWise
		cMD := "1"
	EndCase

//ConOut("xRelTabPre - Monta query para GetPreco.")
	FWLogMsg("INFO", /*cTransactionId*/, "Compras", "xRelTabPre", /*cStep*/, /*cMsgId*/, "Monta query para GetPreco.", /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	cQry += " SELECT "
	cQry += " AIB_PRCCOM, "
	cQry += " AIB_DATVIG "
	cQry += " FROM "+RetSqlName("AIB")+" B  "
	cQry += " INNER JOIN "+RetSqlName("AIA")+" A ON  "
	cQry += " 	A.AIA_FILIAL     = B.AIB_FILIAL  "
	cQry += " 	AND A.AIA_CODFOR = B.AIB_CODFOR  "
	cQry += " 	AND A.AIA_CODTAB = B.AIB_CODTAB  "
	cQry += " 	AND A.AIA_LOJFOR = B.AIB_LOJFOR  "
	cQry += " WHERE  "
	cQry += "   	A.AIA_CODTAB  ='"+cCodTab+"' "
	cQry += " 	AND B.AIB_MOEDA   = '"+cMD+"'
	cQry += " 	AND B.AIB_CODFOR  = '"+cCodFor+"' "
	cQry += " 	AND B.AIB_LOJFOR  = '"+cLojaFor+"' "
	cQry += " 	AND B.AIB_CODPRO  = '"+cProduto+"' "
	cQry += " 	AND B.AIB_INDLOT  = '"+cLotePreco+"' "
	cQry += " 	AND B.AIB_DATVIG >= '"+cDataDe+"' "
	cQry += " 	AND B.D_E_L_E_T_  = '' "
	cQry += " 	AND A.D_E_L_E_T_  = '' "
	cQry += " ORDER BY AIB_DATVIG "

	If Select("QRYPRODU") <> 0
		DbSelectArea("QRYPRODU")
		DbCloseArea()
	EndIf

	TCQuery cQry New Alias "QRYPRODU"

	AADD(aPreco,{QRYPRODU->AIB_PRCCOM,QRYPRODU->AIB_DATVIG})

	QRYPRODU->(DbCloseArea())

Return aPreco

Static Function getMsg(cProduto,cCodFor,cLojaFor)

	Local cMsg := ""
	Local cQry := ""

	cQry += " SELECT TOP 1 AIB_XOBS FROM AIB030 A "
	cQry += "	WHERE  "
	cQry += "	A.D_E_L_E_T_ = '' AND "
	cQry += "	A.AIB_CODPRO = '"+cProduto+"' AND "
	cQry += "	A.AIB_CODFOR = '"+cCodFor+"' AND "
	cQry += "	A.AIB_LOJFOR = '"+cLojaFor+"' AND "
	cQry += "	A.AIB_XOBS <> '' "
	cQry += " ORDER BY AIB_DATVIG DESC "

	If Select("QRYPMSG") <> 0
		DbSelectArea("QRYPMSG")
		DbCloseArea()
	EndIf

	TCQuery cQry New Alias "QRYPMSG"

	cMsg := QRYPMSG->AIB_XOBS

	QRYPMSG->(DbCloseArea())

Return cMsg
