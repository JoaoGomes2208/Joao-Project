#INCLUDE 'protheus.ch'
#INCLUDE 'Topconn.ch'
#INCLUDE 'tbiconn.ch'
//------------------------------------------------------------------------
/*/{Protheus.doc} WORKPREM
AViso para premix usado em produção

@type function
@author Jonatas Paiva / Leonardo Aliberte
@since 12/10/2020
@version P12 
@return html
/*/
//------------------------------------------------------------------------
User Function WORKTRAR() 
Local aXEmpFil  := {"03","01"}  
Local _cTo      := "ti@prodiet.com.br;gq@prodiet.com.br"
Local _cAssunto := "Aviso - Movimentações do Armazém T1 e S3"
Local _cCab     := ""
Local _cMsg     := ""
Local _cRod     := ""
Local cQuery    := ""
Local dMesPass	:= MonthSub(Date(),1)
Local dDtIni	:= FirstDay(dMesPass)
Local dDtFim	:= LastDay(dMesPass)

//Prepara o ambiente para não precisar logar no sistema
PREPARE ENVIRONMENT EMPRESA aXEmpFil[1] FILIAL aXEmpFil[2] FUNNAME FunName() TABLES "SD3"

cQuery += " SELECT "
cQuery += "	D3A.D3_FILIAL FIL, "
cQuery += "	D3A.D3_COD CODIGO, "
cQuery += "	B1.B1_DESC DESCRICAO, "
cQuery += "	D3A.D3_QUANT QUANTIDADE, "
cQuery += "	D3A.D3_LOCAL LOCAL_ENTRADA, "
cQuery += "	D3B.D3_LOCAL LOCAL_SAIDA, "
cQuery += "	D3A.D3_DOC DOCUMENTO, "
cQuery += "	D3A.D3_EMISSAO EMISSAO, "
cQuery += "	X5.X5_DESCRI MOTIVO, "
cQuery += "	D3A.D3_LOTECTL LOTE, "
cQuery += "	D3A.D3_CUSTO1 CUSTO "
cQuery += " FROM SD3030 D3A  "
cQuery += "	INNER JOIN SD3030 D3B ON D3A.D3_FILIAL = D3B.D3_FILIAL AND D3A.D3_COD = D3B.D3_COD AND " 
cQuery += "				D3A.D3_DOC = D3B.D3_DOC AND D3B.D3_LOCAL NOT IN ('T1','S3') AND D3B.D3_CF IN ('RE4','RE6') AND D3B.D_E_L_E_T_ ='' AND D3B.D3_ESTORNO <> 'S' "
cQuery += "	INNER JOIN SB1030 B1 ON D3A.D3_COD = B1.B1_COD AND B1.D_E_L_E_T_ =''  " 
cQuery += " LEFT JOIN SX5030 X5 ON X5_TABELA = 'ZH' AND X5_CHAVE = D3A.D3_XMOTTRA AND X5.D_E_L_E_T_ ='' "
cQuery += " WHERE "
cQuery += "	D3A.D3_EMISSAO BETWEEN '"+DTOS(dDtIni)+"' AND '"+DTOS(dDtFim)+"'AND " 
cQuery += "	D3A.D_E_L_E_T_ ='' AND  "
cQuery += "	D3A.D3_ESTORNO <>'S' AND  "
cQuery += "	D3A.D3_CF IN ('DE4','DE6') AND " 
cQuery += "	D3A.D3_LOCAL IN ('T1','S3') "
cQuery += " ORDER BY D3A.D3_EMISSAO, D3A.D3_COD "

If (Select ("QRY")<> 0)
	QRY->(DbCloseArea())
EndIf

TcQuery cQuery New Alias "QRY" 
	_cCab :=  	U_Imagem("CabEmail")
	_cCab += 	U_Imagem("CabInfo") 
	_cCab += " 		<table width='850' border='0' align='left' bgcolor='#ffffff'> "
	_cCab += " 			<tbody> "
	_cCab += " 				<p> Prezado Depto. de Qualidade, <br /> "
	_cCab += " 					Segue relação de MOTIVOS de transferência para o T1|S3. Data de envio do relatório: " + DTOC(Date()) + " "		
	_cCab += " 				</p> "
	_cCab += " 				Período avaliado: "+DTOC(dDtIni)+" até "+DTOC(dDtFim)+" "
	_cCab += " 				</p> "
	_cCab += " 				<tr> "
	_cCab += " 					<td align='justify'> "
	_cCab += " 						<table class='bottomBorder'> "
	_cCab += " 							<tbody> "
	_cCab += " 								<tr> "
	_cCab += " 									<th> Filial </th> " 
	_cCab += " 									<th> Código </th> " 
	_cCab += " 									<th> Descrição </th> " 
	_cCab += " 									<th> Armazém Origem </th> " 
	_cCab += " 									<th> Armazém Destino </th> "
	_cCab += " 									<th> Quantidade </th> "
	_cCab += " 									<th> Lote </th> "
	_cCab += " 									<th> Data </th> "
	_cCab += " 									<th> Motivo </th> "
	//_cCab += " 									<th> Custo </th> "
	_cCab += " 								</tr> "

	While QRY->(!EoF()) 
	
		_cMsg += "               <tr> "
		_cMsg += "                  <td > " + QRY->FIL + " </td> " 
		_cMsg += "                  <td > " + QRY->CODIGO + " </td> "
		_cMsg += "                  <td > " + QRY->DESCRICAO + " </td> "
		_cMsg += "                  <td > " + QRY->LOCAL_SAIDA + " </td> "
		_cMsg += "                  <td > " + QRY->LOCAL_ENTRADA + " </td> "
		_cMsg += "                  <td > " +Transform(QRY->QUANTIDADE,"@E 999,999.99")  + " </td> "
		_cMsg += "                  <td > " + QRY->LOTE + " </td> "
		_cMsg += "                  <td > " + DTOC(STOD(QRY->EMISSAO)) + " </td> "
		_cMsg += "                  <td > " + AllTrim(QRY->MOTIVO) + " </td> "
	//	_cMsg += "                  <td > " +Transform(QRY->CUSTO,"@E 999,999.99")  + " </td> "
		_cMsg += "               </tr> "
	
		QRY->(DbSkip())
	
	EndDo
	
	_cRod += 	 U_Imagem("RodEmail")
	_cRod += 	 U_Imagem("RodInfo") 

	QRY->(dbCloseArea())
	
		//Envia e-mail para o cliente
		U_SendEMail(,,,,_cTo,_cAssunto,_cCab + _cMsg + _cRod,) 
Return()


//------------------------------------------------------------------
Static Function buscaPA(cOP)
Local aDados := {} 
Local cQuery := "" 

cQuery += " SELECT D3_COD, D3_LOTECTL FROM "+RetSqlName("SD3") "
cQuery += " WHERE D3_QUANT > 0 AND D3_CF = 'PR0' AND D3_OP = '" +cOP+ "' AND " 
cQuery += " D3_ESTORNO <> 'S' AND D_E_L_E_T_ = '' " 
cQuery += " GROUP BY D3_COD, D3_LOTECTL " 

If (Select ("QRY2")<> 0)
	QRY2->(DbCloseArea())
EndIf

TcQuery cQuery New Alias "QRY2"

While QRY2->(!Eof())
	aadd(aDados,{ QRY2->D3_COD, QRY2->D3_LOTECTL})
	QRY2->(DbSkip())
End

QRY2->(dbCloseArea())
Return aDados
