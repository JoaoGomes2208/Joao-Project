#include "Protheus.ch"
#include "topconn.ch"
#include "rwmake.ch"
//------------------------------------------------------------------------------------------
/*/{Protheus.doc} Mt120Fim 
Descrição:
LOCALIZAÇÃO: O ponto se encontra no final da função A120PEDIDO
EM QUE PONTO: Após a restauração do filtro da FilBrowse depois de fechar a operação realizada no pedido de compras, é a ultima instrução da função A120Pedido.

Sintaxe
MT120FIM ( [ @nOpca ], [ @cNumPC ] )

// Wf para criação/alteração/exclusão do pedido de compras
@author    Leonardo Aliberte
@version   1.00
@since     29.03.2022
/*/
//------------------------------------------------------------------------------------------
User Function  Mt120Fim()
	Local nOpcaoA := PARAMIXB[1]   // Opção Escolhida pelo usuário || 2 - Visualização || 3 - Inclusão || 4 - Alteração || 5 - Exclusão || 9 - Cópia
	Local cNumPC  := PARAMIXB[2]   // Numero do Pedido de Compras
	Local nOpcaoB := PARAMIXB[3]   // Indica se a ação foi Cancelada = 0  ou Confirmada = 1 || 0 - Botão "Cancelar" || 1 - Botão "Salvar"

	Local nPosItem := aScan(aHeader,{|x| AllTrim(x[2]) == 'C7_ITEM'})
	Local nPosProd := aScan(aHeader,{|x| AllTrim(x[2]) == 'C7_PRODUTO'})
	Local nPosQtde := aScan(aHeader,{|x| AllTrim(x[2]) == 'C7_QUANT'})
	Local nPosDtEn := aScan(aHeader,{|x| AllTrim(x[2]) == 'C7_DATPRF'})
	Local nPosDesc := aScan(aHeader,{|x| AllTrim(x[2]) == 'C7_DESCRI'})
	Local nPosQtOr := aScan(aHeader,{|x| AllTrim(x[2]) == 'C7_XQTORIG'})
	Local nPosDtOr := aScan(aHeader,{|x| AllTrim(x[2]) == 'C7_XDTORIG'})
	Local nPosNSC  := aScan(aHeader,{|x| AllTrim(x[2]) == 'C7_NUMSC'})
	Local nPosISC  := aScan(aHeader,{|x| AllTrim(x[2]) == 'C7_ITEMSC'})

	Local _nDel    := len(acols[1]) //D_E_L_E_T_

	Local _cCab     := ""
	Local _cMsg     := ""
	Local _cRod     := ""
	Local _cAssunto := ""
//Local _cTo      := "laliberte@prodiet.com.br"
	Local _cTo      := "mklima@prodiet.com.br;pcmpcp@prodiet.com.br"//"jvitor@prodiet.com.br;tjesus@prodiet.com.br;edahle@prodiet.com.br"//
	Local _nCount   := 0
	Local _nI       := 0

// Se clicado no botão "Salvar" e opção maior que Visualização (2)
	If nOpcaoB = 1 .and. nOpcaoA > 2 .or. FWIsInCallStack("CNTA121")
		FWLogMsg("INFO", /*cTransactionId*/, "Compras", "Mt120Fim", /*cStep*/, /*cMsgId*/, "Inicia HTML do pedido de compras.", /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		_cCab += 			U_Imagem("CabEmail")
		_cCab += 			U_Imagem("CabInfoPeq")
		_cCab += "			<table width='850' border='0' align='left' bgcolor='#ffffff'> "
		_cCab += "				<tbody> "

		If nOpcaoA == 3 .or. nOpcaoA == 9 //Inclusão ou cópia de pedido
			_cCab +=  '  <tr bgcolor="#00FF7F"> PEDIDO DE COMPRA INCLUÍDO </tr>'
			_cAssunto += "Pedido de compra incluído"
			If nOpcaoA == 3
				RecLock('SC7',.F.)
				SC7->C7_XDTORIG := aCols[1][nPosDtEn] //DATA DE ENTREGA ORIGINAL -- ATUALIZADO POR: JOAO GOMES
				SC7->C7_XQTORIG := aCOLS[1][nPosQtde] //QUANTIDADE ORIGINAL -- ATUALIZADO POR: JOAO GOMES
				SC7->(MsUnlock())
			EndIf
		ElseIf nOpcaoA == 4 //Alteração
			_cCab +=  '  <tr bgcolor="#DAA520"> PEDIDO DE COMPRA ALTERADO </tr>'
			_cAssunto += "Pedido de compra alterado"
		ElseIf nOpcaoA == 5 //Exclusão
			_cCab +=  '  <tr bgcolor="#FF1919"> PEDIDO DE COMPRA EXCLUÍDO </tr>'
			_cAssunto += "Pedido de compra excluído"
		EndIf

		_cCab += "					<tr> "
		_cCab += "						<td align='justify'> "
		_cCab += "							<table class='bottomBorder'> "
		_cCab += "								<tbody> "
		_cCab += "									<tr class=''>  "
		_cCab += "										<th>Fil - Pedido </th> "
		_cCab += "										<th>Emissão </th> "
		_cCab += "										<th>Fornecedor </th> "
		_cCab += "										<th>Item - Cód. Prod. </th> "
		_cCab += "										<th>Desc. produto </th> "
		_cCab += "										<th>Qtde Original </th> "
		If nOpcaoA == 4 //Verifica se é alteração
			_cCab += "										<th>Qtde Alterada </th> "
		EndIf
		_cCab += "										<th>Dt. entrega Original</th> "
		If nOpcaoA == 4 //Verifica se é alteração
			_cCab += "										<th>Dt. En. Alterada </th> "
		EndIf
		_cCab += "										<th>Status </th> "
		_cCab += "									</tr> "

		FWLogMsg("INFO", /*cTransactionId*/, "Compras", "Mt120Fim", /*cStep*/, /*cMsgId*/, "Impressão dos itens do pedido de compra.", /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		For _nI := 1 To Len(aCols)
			If Posicione("SB1",1,xFilial("SB1")+aCols[_nI][nPosProd],"B1_TIPO") $ 'MP|EM'
				_cMsg += "	<tr>"
				_cMsg += "		<td>" + cFilAnt + " - " + cNumPC + " </td> "
				_cMsg += "		<td>" + DtoC(dA120Emis) + " </td> "
				_cMsg += "		<td>" + cA120Forn + cA120Loj + " </td> "
				_cMsg += "		<td>" + aCols[_nI][nPosItem] + " - " + AllTrim(aCols[_nI][nPosProd]) + " </td> "
				_cMsg += "		<td>" + AllTrim(aCols[_nI][nPosDesc]) + " </td> "
				If nOpcaoA ==4
					_cMsg += "		<td>" + Transform(aCols[_nI][nPosQtoR],"@E 9,999,999.99") + " </td> "
				EndIf
				_cMsg += "		<td>" + Transform(aCols[_nI][nPosQtde],"@E 9,999,999.99") + " </td> "
				if nOpcaoA == 4 //Verifica se é alteração
					_cMsg += "		<td>" + DtoC(aCols[_nI][nPosDtOr]) + " </td> "
				EndIf
				_cMsg += "		<td>" + DtoC(aCols[_nI][nPosDtEn]) + " </td> "
				If aCols[_nI][_nDel]//aCols[_nI][96] // Posição 96 - Campo D_E_L_E_T_
					_cMsg += "		<td bgcolor='#FF1919'> Item excluído. </td>"
				Else
					_cMsg += "		<td> Item incluído ou alterado. </td>"
				EndIf
				_cMsg += "	</tr> "
				_nCount++
			EndIf
		Next

		_cAssunto += " - " + AllTrim(aCols[1][nPosProd]) +" "+ AllTrim(aCols[1][nPosDesc]) // Deve ser 1, para que traga a descrição apenas do primeiro produto
		FWLogMsg("INFO", /*cTransactionId*/, "Compras", "Mt120Fim", /*cStep*/, /*cMsgId*/, "Impressão do rodapé do pedido de compra.", /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		_cRod += 				U_Imagem("RodEmail")
		_cRod += 				U_Imagem("RodInfoPeq")
	EndIf

	If _nCount > 0
		U_SendEMail(,,,,_cTo,_cAssunto,_cCab + _cMsg + _cRod,)
		FWLogMsg("INFO", /*cTransactionId*/, "Compras", "Mt120Fim", /*cStep*/, /*cMsgId*/, "Enviado e-mail de " + Iif(nOpcaoA=9,"cópia",Iif(nOpcaoA=3,"inclusão",Iif(nOpcaoA=4,"alteração","exclusão"))) + " de pedido de compra.", /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	Else
		FWLogMsg("INFO", /*cTransactionId*/, "Compras", "Mt120Fim", /*cStep*/, /*cMsgId*/, "Não há dados para pedido de compra ou pedido visualizado.", /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	EndIf


	If nOpcaoA == 5 .AND. nOpcaob == 1
		For _nI := 1 To Len(aCols)
			DBSelectArea('SC1')
			SC1->(DbSetOrder(1))
			If SC1->(DbSeek(xFilial()+ aCols[_nI][nPosNSC]+ aCols[_nI][nPosISC]+ "     "))
				If RecLock('SC1',.F.)
					SC1->C1_PRODUTO := SC1->C1_PRDREF //É PRA SER ISSO 
					SC1->(MsUnlock())
				EndIf
			EndIf
		Next
	EndIf

Return
