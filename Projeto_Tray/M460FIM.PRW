#include "rwmake.ch"
#include "totvs.ch"
#include "protheus.ch"
#include "pdeco01.ch"
#include "topconn.ch"
#include "fileio.ch"
#include "TBICONN.ch"
#INCLUDE "FWMVCDef.ch"
//------------------------------------------------------------------------------------------
/*/{Protheus.doc} M460FIM
- INCLUI O NUMERO DO CONTRATO NA NOTA FISCAL
- ADICIONA INFORMACOES COMPLEMENTARES NA CDL QUANDO É EXPORTACAO
 -- Adicionado em 12/07 - Impressao de PickList do SC5->c5_xpick
@type function
@author    Jonatas Paiva
@version   1.0

 -- Adicionado alteração do campo F2_PBRUTO, quanto for nota de exportação. 
@author    Leonardo Canto Aliberte
@version   2.0
@since     09/02/2022

 -- Adicionado alteração do campo C5_XAGEND,. se sim, envia aviso para usuarios. 
@author    JONATAS PAIVA
@version   3.0
@since     26/04/2022

 -- Adicionado linha para imprimir pedido Prodiet. 
@author    JONATAS PAIVA
@version   4.0
@since     20/09/2022
' Pedido interno Prodiet: ' + AllTrim(SD2->D2_PEDIDO)

 -- Adicionado linha para TROCAR PESO LIQUIDO DA NF DE EXPORTAÇÃO, ACERTO DE CASA DECIMAL DO CONVDIP. 
@author    JONATAS PAIVA
@version   4.0
@since     20/09/2023

 -- Descomentado linhas para preencher o campo F2_XPDATEN
@author    Giulliano Pinheiro
@version   4.0
@since     25/09/2023

 -- Criada a Funcao FrFyTray para enviar pedidos faturados da Tray para o envio de carga do Fretefy
@author    Giulliano Pinheiro
@version   4.0
@since     14/05/2024
/*/
//------------------------------------------------------------------------------------------
User function M460FIM()
	Local _aRet      := {}
	Local _aArea     := GetArea()
	Local _lM460FIA  := SuperGetMV("MV_M460FIA",.F.,.T.)
//Local _lM460FIB  := SuperGetMV("MV_M460FIB",.F.,.F.) 
	Local _lM460FIC  := SuperGetMV("MV_M460FIC",.F.,.T.)
	Local _lM460FID  := SuperGetMV("MV_M460FID",.F.,.F.)
	Local _lM460FIE  := SuperGetMV("MV_M460FIE",.F.,.T.)
	Local _lM460FIF  := SuperGetMV("MV_M460FIF",.F.,.T.)
//Local _lM460FIG  := SuperGetMV("MV_M460FIG",.F.,.T.) 
	Local _lM460FIH  := SuperGetMV("MV_M460FIH",.F.,.T.)
	Local _lM460FII  := SuperGetMV("MV_M460FII",.F.,.T.)
//Local _lCampos   := (SC5->(FieldPos("C5_XNUMCON")) > 0) //Valida existencia do campo do contrato 
	Local _lCampoE   := (SC5->(FieldPos("C5_XLEMB"))   > 0)
	Local _lCampoP   := (SC6->(FieldPos("C6_XMOTBX"))  > 0)
	Local _lCampoR   := (SC5->(FieldPos("C5_XREGIAO")) > 0)
	Local _cChaveSF2 :=	SF2->( F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA )
	Local _cPedido   := POSICIONE("SD2",3,_cChaveSF2,"D2_PEDIDO")
	Local _cEst      := AllTrim(SA1->A1_EST)
	Local _cPais     := AllTrim(SA1->A1_PAIS)
	//Local _cIdTran	 := ''
//Local _cOPubl    := AllTrim(SA1->A1_OP)
//Local _cNumCom   := "" 
	Local _cLocEmb   := ""
	Local _cLocDes   := ""
	Local _cUFemb    := ""
	Local _cNumRE    := ""
	Local _cCluster  := ""
//Local _cMsgNF    := "" 
	Local _cTipoConv := ""
	Local _nConvDipi := 0
	Local _nPesoTot  := 0
	Local _aDados	 := {}
//Local _nFatorCon := 0 
	Local _nPesPall  := 0
	Local _nPesCxt   := 0
	Local _cAgenda   := SC5->C5_XAGEND //1=Sim;2=Nao add Jonatas 20220426
	Local _nDecCvDip := GetSX3Cache("B5_CONVDIP", "X3_DECIMAL")
	Local _lExport   := (_cEst == "EX" .and. SF2->F2_TIPO != 'B') //Alterado 29.02.2024, para que a tome a nota de complemento // AllTrim(SF2->F2_TIPO) == "N")
	Private _cTipoNF := SF2->F2_TIPO

// Atualizar o status do PV no Mercos
	If !empty(SC5->(fieldPos("C5_XNUMINT")))
		startJob("U_PDEcoNo", GetEnvServer(), .f., {cEmpAnt, cFilAnt, xFilial("SC5"), _cPedido, MCST_ENCERRADO})  // Status liberado definito do PDECO01.CH
	EndIf

//Envia aviso, caso seja agendamento
	If AlLTrim(_cAgenda) == "1" // Sim
		U_XAVIAGE(_cChaveSF2)
	EndIf

	If _lM460FII
		U_INTFRE01({"F",SC5->C5_NUM,"I",SC5->C5_FILIAL})
	EndIf

//Pedidos da tray
	if UPPER(allTrim(SC5->C5_XORIGEM)) = "TRAY" .AND. SC5->C5_FILIAL = "03"
		AAdd(_aDados, SC5->C5_FILIAL)
		AAdd(_aDados, SC5->C5_NUM)
		AAdd(_aDados, SA1->A1_EST)
		AAdd(_aDados, SF2->F2_CHVNFE)
		AAdd(_aDados, ALLTRIM(SF2->F2_SERIE))
		AAdd(_aDados, ALLTRIM(SF2->F2_DOC))
		U_FrFyTray(_aDados)
	endif
//////////////////////////////////////////////////////////////////////

//Verifica se Entra no PE 
	If(_lM460FIA .AND. _lM460FIF .AND. _lCampoE)
		//verifica se é exportacao e tipo Normal
		If _lExport //(_cEst == "EX"  .AND. AllTrim(SF2->F2_TIPO) == "N")
			dbSelectArea("CDL")
			dbSetOrder(1)

			dbSelectArea("SD2")
			dbSetOrder(3) //D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEM

			SD2->(DbSeek(_cChaveSF2))
			_cLocEmb  := AllTrim(SC5->C5_LOCEMBA)
			_cUFemb   := AllTrim(SC5->C5_UFEMBA)
			_cLocDes  := AllTrim(SC5->C5_XLEMB)
			_cNumRE	  := AllTrim(SC5->C5_NUMRE)

			While (SD2->(D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA) == _cChaveSF2 )
				//Cálculo para o peso bruto e líquido dos produtos, para NF de exportaçção
				_cTipoConv := Posicione("SB1", 1, xFilial("SB1")+SD2->D2_COD, "B1_TIPCONV")
				_nConvDipi := 	Posicione("SB5", 1, xFilial("SB5")+SD2->D2_COD, "B5_CONVDIP")
				If _cTipoConv == "D"
					//_nFatorCon := round((1/_nConvDipi),_nDecCvDip)
					//_nPesoTot  += SD2->D2_QUANT * _nFatorCon
					_nPesoTot += NoRound(SD2->D2_QUANT / _nConvDipi, _nDecCvDip) //ADDD JONATAS 20230921
				Else
					_nPesoTot += NoRound(SD2->D2_QUANT * _nConvDipi, _nDecCvDip)
				EndIf
				RecLock("CDL",.T.)
				CDL->CDL_FILIAL := xFilial("CDL")
				CDL->CDL_DOC    := SF2->F2_DOC
				CDL->CDL_SERIE  := SF2->F2_SERIE
				CDL->CDL_ESPEC  := "SPED"
				CDL->CDL_CLIENT := SF2->F2_CLIENTE
				CDL->CDL_LOJA   := SF2->F2_LOJA
				CDL->CDL_PAIS   := _cPais
				CDL->CDL_UFEMB  := _cUFemb
				CDL->CDL_LOCEMB := _cLocEmb
				CDL->CDL_ITEMNF := SD2->D2_ITEM
				CDL->CDL_PRODNF := SD2->D2_COD
				CDL->CDL_LOCDES := _cLocDes
				CDL->CDL_NUMDE  := _cNumRE
				CDL->CDL_INDDOC := "0" //Quando for 1-indireta, teremos que levar a chave da nota fiscal de origem da compra.
				CDL->(MsUnlock())
				SD2->(dbSkip())
			EndDo
			SD2->(dbCloseArea())
		EndIf //Fim _cEst EX
	EndIf

//Verifica se campos customizados estão criados no ambiente.
//Se não estiverem criados, cancela a execução dessa rotina.
//Adiciona Numero Contrato Licitação
/*
If ( _lCampos .AND. _lM460FIB )
	_cNumCom	 := AllTrim(Posicione("SC5",1,xFilial("SC5")+_cPedido,"C5_XNUMCON"))
	//_cPick		 := AllTrim(Posicione("SC5",1,xFilial("SC5")+_cPedido,"C5_XPICK"))
	
	If !Empty(_cNumCom)

		//dbSelectArea("SD2")
		SD2->(dbSetOrder(3)) //D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEM 
		
		SD2->(DbSeek(_cChaveSF2)) 
		While (SD2->(D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA) == _cChaveSF2 )  
			RecLock("SD2", .F.)
				SD2->D2_XNUMCON := _cNumCom //numero do contrato de licitacao
			//	SF2->F2_XPICK	 := _cPick // se o pick foi impresso
			MsUnLock()    
			SD2->(dbSkip()) 
		End 
	EndIf
EndIf
*/
	If _lM460FID
		If cFilAnt == GetNewPar("MV_XFILDEP","03") .and. SF2->F2_CLIENTE == GetNewPar("MV_XCLIMAT","000431") .and. SF2->F2_LOJA == GetNewPar("MV_XLOGMAT","01")
			BeginSql Alias "QZC1"
			SELECT R_E_C_N_O_ RECZC1
			FROM
			%table:ZC1%
			WHERE
			ZC1_FILIAL = %exp:SF2->F2_FILIAL% 	AND
			ZC1_DOCSAI = %exp:SF2->F2_DOC% 		AND
			ZC1_SERSAI = %exp:SF2->F2_SERIE% 	AND
			D_E_L_E_T_ = ' '
			EndSql

			While QZC1->(!Eof())
				ZC1->(dbGoTo(QZC1->RECZC1))

				RecLock("ZC1",.F.)
				ZC1->(dbDelete())
				ZC1->(MsUnLock())

				QZC1->(dbSkip())
			Enddo
			QZC1->(dbCloseArea())

			BeginSql Alias "QSD2"
			SELECT *
			FROM
			%table:SD2% SD2
			INNER JOIN %table:SF4% SF4 ON D2_FILIAL = F4_FILIAL AND D2_TES = F4_CODIGO AND F4_ESTOQUE = 'S' AND SF4.D_E_L_E_T_ = ' '
			WHERE
			D2_FILIAL 		= %exp:SF2->F2_FILIAL% 	AND
			D2_DOC 			= %exp:SF2->F2_DOC%		AND
			D2_SERIE 		= %exp:SF2->F2_SERIE% 	AND
			SD2.D_E_L_E_T_ 	= ' '
			EndSql

			While QSD2->(!Eof())
				BeginSql Alias "QZC0"
				SELECT ZC0.R_E_C_N_O_ RECZC0
				FROM
				%table:ZC0% ZC0
				INNER JOIN %table:SF1% SF1 ON F1_FILIAL = ZC0_FILIAL AND F1_DOC = ZC0_DOC AND F1_SERIE = ZC0_SERIE AND
				ZC0_FORNEC = F1_FORNECE AND ZC0_LOJA = F1_LOJA AND SF1.D_E_L_E_T_ = ' '
				WHERE
				ZC0_FILIAL 		= %exp:QSD2->D2_FILIAL% 	AND
				ZC0_COD			= %exp:QSD2->D2_COD%  		AND
				ZC0_LOTE 		= %exp:QSD2->D2_LOTECTL% 	AND
				ZC0_SALDO		> 0 AND
				ZC0.D_E_L_E_T_  = ' '
				EndSql

				nQtdSld:= QSD2->D2_QUANT

				While QZC0->(!Eof())
					ZC0->(dbGoTo(QZC0->(RECZC0)))
					nQtdSld-= ZC0->ZC0_SALDO

					RecLock("ZC1",.T.)
					ZC1->ZC1_FILIAL := xFilial("ZC1")
					ZC1->ZC1_DOCSAI := QSD2->D2_DOC
					ZC1->ZC1_SERSAI := QSD2->D2_SERIE
					ZC1->ZC1_ITEM   := QSD2->D2_ITEM
					ZC1->ZC1_COD 	:= QSD2->D2_COD
					ZC1->ZC1_LOTE 	:= QSD2->D2_LOTECTL
					ZC1->ZC1_QUANT 	:= Iif(nQtdSld <= 0, QSD2->D2_QUANT, ZC0->ZC0_SALDO)
					ZC1->ZC1_DOCENT := ZC0->ZC0_DOC
					ZC1->ZC1_SERENT := ZC0->ZC0_SERIE
					ZC1->ZC1_FORENT := ZC0->ZC0_FORNEC
					ZC1->ZC1_LOJENT := ZC0->ZC0_LOJA
					ZC1->(MsUnLock())

					RecLock("ZC0",.F.)
					ZC0->ZC0_SALDO -= iif(nQtdSld <= 0, QSD2->D2_QUANT, ZC0->ZC0_SALDO)
					ZC0->(MsUnLock())

					If nQtdSld <= 0
						Exit
					EndIf
					QZC0->(dbSkip())
				Enddo
				QZC0->(dbCloseArea())
				QSD2->(dbSkip())
			Enddo
			QSD2->(dbCloseArea())
		EndIf
	EndIf

	If ( _lCampoP .AND. _lM460FIC )
		dbSelectArea("SD2")
		dbSetOrder(3) //D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEM

		dbSelectArea("SC6")
		dbSetOrder(1) //C6_FILIAL+C6_PEDIDO+C6_ITEM

		//_cNumCom	 := AllTrim(Posicione("SC5",1,xFilial("SC5")+_cPedido,"C5_XNUMCON"))
		SD2->(DbSeek(_cChaveSF2))
		While (SD2->(D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA) == _cChaveSF2 )

			// POSICIONA NA SC6 - PARA ENCONTRAR O MOTIVO DA BAIXA
			If SC6->(DbSeek(SD2->(D2_FILIAL+D2_PEDIDO+D2_ITEMPV)))
				RecLock("SD2",.F.)
				SD2->D2_XMOTBX 	:= SC6->C6_XMOTBX
				MsUnlock()
			EndIf
			SD2->(dbSkip())
		EndDo
		SD2->(dbCloseArea())
		SC6->(dbCloseArea())
	EndIf

//Grava a Região e o Cluster Custom
	If ( _lCampoR .AND. _lM460FIE )
		_cRegiao	:= AllTrim(Posicione("SC5",1,SF2->F2_FILIAL+_cPedido,"C5_XREGIAO")) //ALTERADO JPAIVA 20220715 DE XFILIAL PARA SD2 FILIAL
		_cTpAtend	:= AllTrim(Posicione("SC5",1,SF2->F2_FILIAL+_cPedido,"C5_XPDATEN")) //ALTERADO JPAIVA 20220715 DE XFILIAL PARA SD2 FILIAL
		_cCluster 	:= AllTrim(Posicione("SA1",1,xFilial("SA1")+SF2->F2_CLIENTE+SF2->F2_LOJA,"A1_XCLUSTE"))
		_cSegmento 	:= AllTrim(Posicione("SA1",1,xFilial("SA1")+SF2->F2_CLIENTE+SF2->F2_LOJA,"A1_TIPO2"))

		If !Empty(_cRegiao)
			RecLock("SF2", .F.)
			SF2->F2_REGIAO	:= _cRegiao
			MsUnLock()
		EndIf
		If !Empty(_cCluster)
			RecLock("SF2", .F.)
			SF2->F2_XCLUSTE	:= _cCluster
			MsUnLock()
		EndIf
		If !Empty(_cSegmento)
			RecLock("SF2", .F.)
			SF2->F2_XTIPO2	:= _cSegmento
			MsUnLock()
		EndIf
		If !Empty(_cTpAtend)
			RecLock("SF2", .F.)
			SF2->F2_XPDATEN	:= _cTpAtend
			MsUnLock()
		EndIf
		//Preenche CC
		dbSelectArea("SD2")
		dbSetOrder(3) //D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEM
		SD2->(DbSeek(_cChaveSF2))

		While (SD2->(D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA) == _cChaveSF2 )
			IF !(SD2->D2_CF $ "151|152")//Se não contem CFOP
				if !Empty(AllTrim(_cSegmento)) //Se nao está vazio Segmento
					RecLock("SD2", .F.)
					SD2->D2_XCCUSTO := U_xSegmeCC(_cSegmento, SD2->D2_EST)
					MsUnLock()
				EndIf
			EndIf
			SD2->(dbSkip())
		EndDo
		SD2->(dbCloseArea())
		RestArea(_aArea)

	EndIf

/*
If ( _lM460FIG )
	If Len(AllTrim(SF2->F2_MENNOTA)) < 251 //campo tem 251 - msg adicionada tem 51 caracteres
		_cMsgNF := ''   
		
		If SF2->F2_EST $ ("DF|RO|CE|MG|SP|SC") .AND. ALLTRIM(SF2->F2_TIPOCLI) == "F" //ADICIONADO EM 20220401
			Do CASE 
				Case SF2->F2_EST == "DF"  
					_cMsgNF += "Acao DIFAL 2022 ajuizada na 4a vara da Fazenda Publica do Distrito Federal sob N 0703761-06.2022.8.07.0018, pagamento via deposito judicial" 
				Case SF2->F2_EST == "RO"  
					_cMsgNF += "Acao DIFAL 2022 ajuizada na 1a vara da Fazenda Publica da Comarca de Porto Velho sob N 7022448-84.2022.8.22.0001, pagamento via deposito judicial"
				Case SF2->F2_EST == "CE"  
					_cMsgNF += "Acao DIFAL 2022 ajuizada no 13a Vara da Fazenda Publica da Comarca de Fortaleza sob n 0224590-46.2022.8.06.0001, pagamento via deposito judicial"
				Case SF2->F2_EST == "MG"  
					_cMsgNF += "Acao DIFAL 2022 ajuizada na 3a vara de Feitos Tributarios do Estado da Comarca de Belo Horizonte sob Na 5058404-78.2022.8.13.0024, pagamento via deposito judicial"
				Case SF2->F2_EST == "SP"  
					_cMsgNF += "Mandato Seguranca DIFAL 2022 ajuizada na 10a vara da Fazenda Publica de Sao Paulo sob N 1011920-23.2022.8.26.0053, pagamento via deposito judicial"
				Case SF2->F2_EST == "SC"  
					_cMsgNF += "Acao DIFAL 2022 ajuizada na 3a Vara da Fazenda Pública de Florianópolis sob N 5041848-95.2022.8.24.0023, pagamento via deposito judicial"
			End Case 
		EndIf 
		
		If _cOPubl <> "N"
			_cMsgNF += ' Conta: BANCO DO BRASIL AG: 3406-1 C/C 5259-0 ' + ' Pedido interno Prodiet: ' + AllTrim(_cPedido) + AllTrim(SF2->F2_MENNOTA) 
		Else 
			_cMsgNF += ' Laudos dos produtos estão em www.prodiet.com.br ' + ' Pedido interno Prodiet: ' + AllTrim(_cPedido) + AllTrim(SF2->F2_MENNOTA) 
		EndIf 
		RecLock("SF2", .F.)
			SF2->F2_MENNOTA	:= _cMsgNF
		MsUnLock()     
	EndIf
EndIf

*/
	If ( _lM460FIH )
		_aRet := MntNF(_lExport) //_aRet{_cEspec, _nVolume, _nPallet, _nCaixote, _lOk}
		While _lExport .and. _aRet[3] == 0 .and. _aRet[4] == 0 .and. _aRet[5]
			If MsgYesNo("Os campos de pallet e caixote não foram preenchidos." +CRLF+;
					"Deseja continuar?","Campo não preenchido")
				Exit
			Else
				MsgAlert('É preciso preencher o campo de pallet e/ou caixote', 'NF exportação')
				_aRet := MntNF(_lExport)
/*			If _aRet[5]
				_nPesPall := _aRet[3] * 23.10 //_nPallet  * 23.10
				_nPesCxt  := _aRet[4] * 58.65 //_nCaixote * 58.65
			EndIf
*/		EndIf
			EndDo

			If _aRet[5] //_lOk
				RecLock("SF2", .F.)
				SF2->F2_ESPECI1 := AllTrim(_aRet[1]) //_cEspec
				SF2->F2_VOLUME1 := _aRet[2] //_nVolume
				If _lExport
					_nPesPall := _aRet[3] * 23.10 //_nPallet  * 23.10
					_nPesCxt  := _aRet[4] * 58.65 //_nCaixote * 58.65
					SF2->F2_PLIQUI  := Round(_nPesoTot,3)
					SF2->F2_PBRUTO  := Round(_nPesoTot,3)+_nPesPall+_nPesCxt
					SF2->F2_XOBSPAL := "O pedido contém: " + cValToChar(_aRet[3]) + " pallet(s), totalizando " + cValToChar(_nPesPall) + " kg e " + cValToChar(_aRet[4]) + " pallet(s) com caixote(s), totalizando " + cValToChar(_nPesCxt) + " kg. || Total de peso: " + cValToChar(_nPesPall+_nPesCxt) +" kg."
				EndIf
				MsUnlock()
				Iif(_lExport,xAvisoNFIB(SF2->F2_FILIAL, SF2->F2_DOC, SF2->F2_SERIE, SF2->F2_EMISSAO, SF2->F2_CLIENTE,SF2->F2_LOJA, SF2->F2_PLIQUI, SF2->F2_PBRUTO, _aRet[3], _nPesPall, _aRet[4], _nPesCxt),"")
			EndIf
		EndIf

		RestArea(_aArea)
		Return


//------------------------------------------------------------------------------------------
/*/{Protheus.doc} MntNF
	Cria o quadro de manutenção de nota fiscal
	@type  Static Function
	@author Leonardo Aliberte
	@since 08.03.2023
	@version 1.0
/*/
//------------------------------------------------------------------------------------------
Static Function MntNF(_lExport)
	Local _lOk     := .F.
	Local oGet1, oGet2
	Local oDlg      := Nil
	Local oFolder   := Nil
	Local oList     := Nil
	Local _aCab     := {RetTitle("F2_DOC"), RetTitle("F2_SERIE"), RetTitle("F2_CLIENTE"), RetTitle("F2_LOJA"), RetTitle("F2_EMISSAO")}
	Local _aIts     := {{SF2->F2_DOC, SF2->F2_SERIE, SF2->F2_CLIENTE, SF2->F2_LOJA, SF2->F2_EMISSAO}}
	Local _cEspec   := Space(10)
	Local _nVolume  := 0
	Local _nPallet  := 0
	Local _nCaixote := 0
	Local _nA       := 0

	Define MSDialog oDlg Title "Manutenção de Nota Fiscal "+ Iif(_lExport, "para exportação", "nacional") From 9, 0 To 28.2, 80

	oFolder	:= TFolder():New(1, 1, {"Nota Fiscal"}, {"HEADER"}, oDlg, Nil, Nil, Nil, .T., .F., 315, 141)
	oList 	:= TWBrowse():New(5, 1, 310, 42, Nil, _aCab, {30, 90, 50, 30, 50}, oFolder:aDialogs[1], Nil, Nil, Nil, Nil, Nil, Nil, Nil, Nil, Nil, Nil, Nil, .F., Nil, .T., Nil, .F., Nil, Nil, Nil)
	oList:SetArray(_aIts)
	oList:bLine	:= {|| {_aIts[oList:nAt][1], _aIts[oList:nAt][2], _aIts[oList:nAt][3], _aIts[oList:nAt][4], _aIts[oList:nAt][5]}}
	oList:lAutoEdit	:= .F.

	@ 50, 5 Say "Manutenção Espécie e Volume" Size 100, 15 Pixel Of oFolder:aDialogs[1]
	@ 55, 5 Say Replicate("_", 50)            Size 100, 10 Pixel Of oFolder:aDialogs[1] //Imprimir linha horizontal
	@ 65, 5 Say RetTitle("F2_ESPECI1")        Size  40, 10 Pixel Of oFolder:aDialogs[1]
	@ 80, 5 Say RetTitle("F2_VOLUME1")        Size  40, 10 Pixel Of oFolder:aDialogs[1]

	@ 65, 50 MSGet oGet1 VAR _cEspec  Picture PesqPict("SF2", "F2_ESPECI1") Size 50, 7 Pixel Of oFolder:aDialogs[1]
	@ 80, 50 MSGet oGet2 VAR _nVolume Picture PesqPict("SF2", "F2_VOLUME1") Size 50, 7 Pixel Of oFolder:aDialogs[1]

	If _lExport .and. _cTipoNF == 'N' //Aparecer a tela de preenchimento apenas para nota tipo normal
		@ 50, 150 Say "Cálculo de peso bruto e líquido" Size 100, 15 Pixel Of oFolder:aDialogs[1]
		@ 55, 150 Say Replicate("_", 50)                Size 100, 10 Pixel Of oFolder:aDialogs[1] //Imprimir linha horizontal
		@ 65, 150 Say "Qtde pallets: "                  Size  40, 15 Pixel Of oFolder:aDialogs[1]
		@ 80, 150 Say "Qtde pallets com caixotes: "     Size  40, 15 Pixel Of oFolder:aDialogs[1]

		@ 65, 200 MSGet oGet1 VAR _nPallet  Picture PesqPict("SF2", "F2_VOLUME1") Size 50, 7 Pixel Of oFolder:aDialogs[1]
		@ 80, 200 MSGet oGet2 VAR _nCaixote Picture PesqPict("SF2", "F2_VOLUME1") Size 50, 7 Pixel Of oFolder:aDialogs[1]

		For _nA := 50 To 100 //Imprimir linha vertical
			@ _nA, 125 Say "|" Size 100, 10 Pixel Of oFolder:aDialogs[1]
		Next
	EndIf

	@ 110,   5 To 111,310 Pixel OF oFolder:aDialogs[1]
	@ 113, 225 Button "Confirmar" Size 40, 13 Font oFolder:aDialogs[1]:oFont Action (_lOk := .T., oDlg:End()) Of oFolder:aDialogs[1] Pixel
	@ 113, 270 Button "Cancelar"  Size 40, 13 Font oFolder:aDialogs[1]:oFont Action               oDlg:End()  Of oFolder:aDialogs[1] Pixel

	Activate MSDialog oDlg Centered
Return {_cEspec, _nVolume, _nPallet, _nCaixote, _lOk}


//------------------------------------------------------------------------------------------
/*/{Protheus.doc} XAVIAGE
Envia Aviso para posvendas
NÚMERO DO PEDIDO
NÚMERO DA NOTA FISCAL
COD DO CLIENTE + LOJA
RAZÃO SOCIAL
TRANSPORTADORA
MENSAGEM DA NOTA FISCAL
OBSERVAÇÕES (C5_OBS)
E-MAIL DO CADASTRO
DATA DE PREVISÃO DE ENTREGA (FRETE EMBARCADOR)

@author    JONATAS PAIVA
@version   2.0
@since     26.04.2022
/*/
//------------------------------------------------------------------------------------------
User Function XAVIAGE(cChave)
	Local _cFilial  := SubStr(cChave, 1, 2)
	Local cNota 	:= SubStr(cChave, 3, 9)
	Local cSerie 	:= SubStr(cChave, 12, 3)
	Local cCodCli 	:= SubStr(cChave, 15, 6)
	Local cLoja 	:= SubStr(cChave, 21, 2)
	Local _cTo 		:= "posvenda@prodiet.com.br; transportes@prodiet.com.br"
	Local _cAssunto := ":: Nota Fiscal "+cNota+" Com Entrega Agendada :: "
	Local cDtEnt	:= ""
	Local _cCab 	:= ""
	Local _cRod 	:= ""
	Local cQuery	:= ""

//conout("M460FIM - Função para enviar e-mail com os dados.")  
	FWLogMsg("INFO", /*cTransactionId*/, "Faturamento", "M460Fim", /*cStep*/, /*cMsgId*/, "Função para enviar e-mail com os dados.", /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	cQuery := " SELECT "
	cQuery += " C5_NUM, "
	cQuery += " A4_NOME, "
	cQuery += " C5_MENNOTA, "
	cQuery += " C5_OBS, "
	cQuery += " A1_NOME, "
	cQuery += " A1_EMAIL, "
	cQuery += " DATA_FRETE = (SELECT GWU_DTPENT FROM "+RetSqlName("GWU")+" (NOLOCK) WHERE GWU_FILIAL = '"+_cFilial+"' AND GWU_NRDC = '"+cNota+"' AND GWU_SERDC = '"+cSerie+"' AND GWU_CDTPDC = 'NFSAI' and D_E_L_E_T_ = ' ' )"
	cQuery += " FROM "+RetSqlName("SC5")+" SC5 (NOLOCK) "
	cQuery += " INNER JOIN "+RetSqlName("SA1")+" SA1 (NOLOCK) "
	cQuery += " ON A1_COD = C5_CLIENTE AND A1_LOJA = C5_LOJACLI AND SA1.D_E_L_E_T_ =' ' "
	cQuery += " INNER JOIN "+RetSqlName("SF2")+" SF2 (NOLOCK) "
	cQuery += " ON F2_FILIAL = C5_FILIAL AND F2_DOC = C5_NOTA AND F2_SERIE = C5_SERIE AND C5_CLIENTE = F2_CLIENTE AND F2_LOJA = C5_LOJACLI AND SF2.D_E_L_E_T_ =' ' "
	cQuery += " LEFT JOIN "+RetSqlName("SA4")+" SA4 (NOLOCK) "
	cQuery += " ON A4_COD = F2_TRANSP AND SA4.D_E_L_E_T_ =' ' "
	cQuery += " WHERE "
	cQuery += " 	SC5.C5_FILIAL  = '"+ _cFilial +"' AND "
	cQuery += " 	SC5.C5_NOTA    = '"+ cNota    +"' AND "
	cQuery += " 	SC5.C5_SERIE   = '"+ cSerie   +"' AND "
	cQuery += " 	SC5.D_E_L_E_T_ = ' ' "

	If (Select ("QRY")<> 0)
		QRY->(DbCloseArea())
	EndIf

	TcQuery cQuery New Alias "QRY"

	If !Empty(ALLTRIM(QRY->DATA_FRETE))
		cDtEnt := DTOC(STOD(QRY->DATA_FRETE))
	EndIf

	//conout("M460FIM - Monta html do e-mail.")
	FWLogMsg("INFO", /*cTransactionId*/, "Faturamento", "M460Fim", /*cStep*/, /*cMsgId*/, "Monta html do e-mail.", /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	_cCab += 		U_Imagem("CabEmail")
	_cCab += 		U_Imagem("CabInfo")
	_cCab += " 		<table width='850' border='0' align='left' bgcolor='#ffffff'> "
	_cCab += " 			<tbody> "
	_cCab += " 				<p> "
	_cCab += "  <p>Entrega com Agendamento</p>"
	_cCab += "       <tr> "
	_cCab += " 		 <td align='justIfy'> "
	_cCab += "          	 <table class='bottomBorder'> "
	_cCab += "                 <tbody> "
	_cCab += "	<tr>"
	_cCab += "		<th>Pedido</th> "
	_cCab += "		<td>" + AllTrim(QRY->C5_NUM) + " </td> "
	_cCab += "	</tr> "
	_cCab += "	<tr>"
	_cCab += "		<th>Nota Fiscal </th> "
	_cCab += "		<td>" + AllTrim(cNota) + " </td> "
	_cCab += "	</tr> "
	_cCab += "	<tr>"
	_cCab += "		<th>Cod Cliente </th> "
	_cCab += "		<td>" + cCodCli + "-" + cLoja + " </td> "
	_cCab += "	</tr> "
	_cCab += "	<tr>"
	_cCab += "		<th>Razao Social</th> "
	_cCab += "		<td>" + AllTrim(QRY->A1_NOME) + " </td> "
	_cCab += "	</tr> "
	_cCab += "	<tr>"
	_cCab += "		<th>Transportadora</th> "
	_cCab += "		<td>" + ALLTRIM(QRY->A4_NOME) + " </td> "
	_cCab += "	</tr> "
	_cCab += "	<tr>"
	_cCab += "		<th>E-mail</th> "
	_cCab += "		<td>" + ALLTRIM(QRY->A1_EMAIL)+ " </td> "
	_cCab += "	</tr> "
	_cCab += "	<tr>"
	_cCab += "		<th>Data Prevista Entrega</th> "
	_cCab += "		<td>" + cDtEnt + " </td> "
	_cCab += "	</tr> "
	_cCab += "	<tr>"
	_cCab += "		<th>Observação Pedido</th> "
	_cCab += "		<td>" + AllTrim(QRY->C5_OBS) + " </td> "
	_cCab += "	</tr> "
	_cCab += "	<tr>"
	_cCab += "		<th>Observação Nota</th> "
	_cCab += "		<td>" + AllTrim(QRY->C5_MENNOTA) + " </td> "
	_cCab += "	</tr> "

	_cRod += 			U_Imagem("RodEmail")
	_cRod += 			U_Imagem("RodInfo")

	If !Empty(_cTo)
		U_SendEMail(,,,,_cTo,_cAssunto,_cCab + _cRod,)
		//conout("M460FIM - E-mail enviado.")
		FWLogMsg("INFO", /*cTransactionId*/, "Faturamento", "M460Fim", /*cStep*/, /*cMsgId*/, "E-mail enviado.", /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	Else
		//conout("M460FIM - Não há dados.")
		FWLogMsg("INFO", /*cTransactionId*/, "Faturamento", "M460Fim", /*cStep*/, /*cMsgId*/, "Não há dados.", /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	EndIf
Return


//---------------------------------------------------------------------------------------------
/*/{Protheus.doc} xAvisoNFIB
	E-mail com a memória de cálculo do peso bruto e líquido para notas do IB
	@type  Static Function
	@author Leonardo Aliberte
	@since 09.03.2023
	@version 1.0
/*/
//---------------------------------------------------------------------------------------------
Static Function xAvisoNFIB(_cFilial, _cNota, _cSerie, _cEmissao, _cCodCte, _cLojaCte, _fPesLiq, _fPesBrut, _nQtdPall, _nPesPall, _nQtdCxt, _nPesCxt)
//Local _cTo      := "ti@prodiet.com.br" 
	Local _cTo      := "ib@prodiet.com.br; transportes@prodiet.com.br; fiscal@prodiet.com.br; ti@prodiet.com.br"
	Local _cAssunto := "Memória de cálculo de peso para nota "+ _cNota
	Local _cCab     := ""
	Local _cMsg     := ""
	Local _cRod     := ""
	Local _cQry     := ""

	// https://tdn.totvs.com/display/public/framework/FWLogMsg
	FWLogMsg("INFO", /*cTransactionId*/, "Faturamento", "M460Fim", /*cStep*/, /*cMsgId*/, "Query para pegar itens da nota.", /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	_cQry += " select D2_COD "
	_cQry += " 	, D2_ITEM "
	_cQry += " 	, D2_LOTECTL "
	_cQry += " 	, B1_DESC "
	_cQry += " 	, D2_QUANT "
	_cQry += " 	, B1_PESBRU "
	_cQry += " 	, D2_QUANT*B1_PESBRU PESO_TOTAL "
	_cQry += " 		from SD2030 D2 (NOLOCK), SB1030 B1 (NOLOCK) "
	_cQry += " 			where D2_COD        = B1_COD "
	_cQry += "			  and D2_FILIAL     = '"+ _cFilial  +"' "
	_cQry += " 			  and D2_DOC        = '"+ _cNota    +"' "
	_cQry += " 			  and D2_SERIE      = '"+ _cSerie   +"' "
	_cQry += " 			  and D2_CLIENTE    = '"+ _cCodCte  +"' "
	_cQry += " 			  and D2_LOJA       = '"+ _cLojaCte +"' "
	_cQry += " 			  and D2.D_E_L_E_T_ = ' ' "
	_cQry += " 			  and B1.D_E_L_E_T_ = ' ' "
	_cQry += " order by D2_ITEM "

	If Select("QRY") > 0
		QRY->(dbCloseArea())
	EndIf
	TcQuery _cQry New Alias "QRY"

	//conout("M460Fim - Inicia montagem do cabeçalho do HTML.")
	FWLogMsg("INFO", /*cTransactionId*/, "Faturamento", "M460Fim", /*cStep*/, /*cMsgId*/, "Monta cabeçalho do e-mail.", /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	_cCab +=   U_Imagem("CabEmail")
	_cCab +=   U_Imagem("CabInfo")
	_cCab += " 	<table width='850' border='0' align='left' bgcolor='#ffffff'> "
	_cCab += " 		<tbody> "
	_cCab += " 			<p> "
	_cCab += " 			<p> Memória de cálculo para a nota de exportação: <u>"+ _cNota +"</u>. </p>"
	_cCab += " 			<tr> "
	_cCab += " 				<td align='justify'> "
	_cCab += " 					<table class='bottomBorder'> "
	_cCab += " 						<tbody> "
	_cCab += " 							<tr class=''>  "
	_cCab += " 								<th> Cliente      </th> "
	_cCab += " 								<th> Razão Social </th> "
	_cCab += " 								<th> Nota Fiscal  </th> "
	_cCab += " 								<th> Dt. Emis.    </th> "
	_cCab += " 								<th> Qtde Pallet   </th> "
	_cCab += " 								<th> Peso Pallet  </th> "
	_cCab += " 								<th> Qtde Caixote  </th> "
	_cCab += " 								<th> Peso Caixote </th> "
	_cCab += " 								<th> Peso Líq.    </th> "
	_cCab += " 								<th> Peso Bruto   </th> "
	_cCab += " 							</tr> "

	//conout("M460Fim - Inicia montagem do corpo do e-mail do HTML.")
	FWLogMsg("INFO", /*cTransactionId*/, "Faturamento", "M460Fim", /*cStep*/, /*cMsgId*/, "Monta corpo do e-mail.", /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	_cMsg += " 		<tr>"
	_cMsg += " 			<td>" + _cCodCte + _cLojaCte + " </td> "
	_cMsg += " 			<td>" + AllTrim(Posicione("SA1",1,xFilial("SA1")+_cCodCte+_cLojaCte,"A1_NOME")) + "</td> "
	_cMsg += " 			<td>" + _cNota + "</td> "
	_cMsg += " 			<td>" + DtoC(_cEmissao) + " </td> "
	_cMsg += " 			<td>" + cValToChar(_nQtdPall) + " </td> "
	_cMsg += " 			<td>" + Transform(_nPesPall, "@E 9,999,999.9999") + " </td> "
	_cMsg += " 			<td>" + cValToChar(_nQtdCxt) + " </td> "
	_cMsg += " 			<td>" + Transform(_nPesCxt,  "@E 9,999,999.9999") + " </td> "
	_cMsg += " 			<td>" + Transform(_fPesLiq,  "@E 9,999,999.9999") + "</td> "
	_cMsg += " 			<td>" + Transform(_fPesBrut, "@E 9,999,999.9999") + "</td> "
	_cMsg += " 		</tr>"
	_cMsg += " 		<tr class=''>  "
	_cMsg += " 			<th> Item / Prod. </th> "
	_cMsg += " 			<th> Descrição    </th> "
	_cMsg += " 			<th> Lote         </th> "
	_cMsg += " 			<th> Qtde         </th> "
	_cMsg += " 			<th> Peso unit.   </th> "
	_cMsg += " 			<th> Peso total   </th> "
	_cMsg += " 		</tr> "

	While QRY->(!Eof())
		FWLogMsg("INFO", /*cTransactionId*/, "Faturamento", "M460Fim", cValToChar(QRY->D2_ITEM), /*cMsgId*/, "Monta itens da nota do e-mail.", /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		_cMsg += " 		<tr>"
		_cMsg += " 			<td>" + QRY->D2_ITEM + " / " + AllTrim(QRY->D2_COD)  + " </td> "
		_cMsg += " 			<td>" + AllTrim(QRY->B1_DESC)     + " </td> "
		_cMsg += " 			<td>" + AllTrim(QRY->D2_LOTECTL)  + " </td> "
		_cMsg += " 			<td>" + cValToChar(QRY->D2_QUANT) + " </td> "
		_cMsg += " 			<td>" + Transform(QRY->B1_PESBRU,  "@E 9,999.9999") + " </td> "
		_cMsg += " 			<td>" + Transform(QRY->PESO_TOTAL, "@E 9,999.9999") + " </td> "
		_cMsg += " 		</tr>"
		QRY->(dbSkip())
	EndDo

	//conout("M460Fim - Inicia montagem do rodapé do HTML.")
	FWLogMsg("INFO", /*cTransactionId*/, "Faturamento", "M460Fim", /*cStep*/, /*cMsgId*/, "Monta rodapé do e-mail.", /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	_cRod += 	U_Imagem("RodEmail")
	_cRod += 	U_Imagem("RodInfo")

	U_SendEMail(,,,,_cTo,_cAssunto,_cCab + _cMsg + _cRod,)
	//conout("M460FIM - E-mail enviado.")
	FWLogMsg("INFO", /*cTransactionId*/, "Faturamento", "M460Fim", /*cStep*/, /*cMsgId*/, "E-mail enviado.", /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
Return

/*/{Protheus.doc} FormatDt
Formata data para integracao no fretefy 
@type function
@author Giulliano Pinheiro
@since 15/05/2024
@param dData, character, data para formatar
@return character, data formatada
/*/
Static Function FormatDt(dData)

	Local cRetData  := ""

	cRetData := substr(dtoS(dData),1,4)+'-'+substr(dtoS(dData),5,2)+'-'+substr(dtoS(dData),7,2)

Return(cRetData)
