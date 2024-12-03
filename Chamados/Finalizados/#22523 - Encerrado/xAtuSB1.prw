#include "protheus.ch"
#include "topconn.ch"
#include "fileio.ch" 
#include "TBICONN.ch"
#include "rwmake.ch"
//------------------------------------------------------------------------------------------
/*/{Protheus.doc} xAtupROD
@author    Jonatas Paiva
@version   1.00
@since     04/10/2018
/*/
//------------------------------------------------------------------------------------------
User Function xAtuProd()
Local aXEmpFil	:= {"03","01"}  
Local nHandle 	:= 0
Local cDir 		:= "C:\Users\jvitor\OneDrive - Prodiet Nutricao Clinica Ltda\Documentos\joao-project\Chamados\#22523"//"/anexos/logs/"
Local cArq 		:= ""

PREPARE ENVIRONMENT EMPRESA aXEmpFil[1] FILIAL aXEmpFil[2] FUNNAME FunName() TABLES "SB1"

cArq := "xatuPROD"+DTOS(Date())+".txt"
nHandle := FCreate(cDir+cArq) 

//valida abertura do arquivo
If nHandle == -1  
	//conout("XATUPROD: Arquivo não pode ser aberto "+ CRLF) 
	FWLogMsg("INFO", /*cTransactionId*/, "Sched", "XATUPROD", /*cStep*/, /*cMsgId*/, "Arquivo não pode ser aberto."+ CRLF, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
EndIf
//posiciona no topo do arquivo		
FT_FGOTOP()       
FWrite(nHandle,"Inicio da Gravação Log "+Time()+ CRLF)

DbSelectArea("SB1")
SB1->(DbSetOrder(1))
SB1->(DbGoTop())

	cQuery:= " SELECT * "
	cQuery+= " FROM "+RetSqlName("SB1")+" SB1  "
	cQuery+= " WHERE  "
	cQuery+= " 	SB1.B1_TIPO IN ('PA','MP') AND SB1.D_E_L_E_T_ = ''  "
	
	If (Select ("QRY")<> 0)
		QRY->(DbCloseArea())
	EndIf

	TcQuery cQuery New Alias "QRY" 

	While QRY->(!EOF())
		SB1->(DbGoTop())
		IF SB1->(dbseek(XFILIAL("SB1")+QRY->B1_COD))	
			IF ALLTRIM(SB1->B1_TIPO) == "PA"
				IF EMPTY(SB1->B1_XDTLANC)	
					cDataC := buscaDtLc(QRY->B1_COD)
					if !Empty(AllTrim(cDataC))
						FWrite(nHandle,"Data Lanc:" + SB1->B1_COD + "-> " + cDataC + CRLF)
						RecLock("SB1",.F.)
							SB1->B1_XDTLANC := StoD(cDataC)
						SB1->(MsUnlock())
					EndIf//DATA NAO VAZIA
				EndIf//DATA VAZIA
				IF !EMPTY(AllTrim(SB1->B1_XMARCAP))//SE MARCA NÃO VAZIA
					IF AT("&",AllTrim(SB1->B1_XMARCAP)) == 0 //se TEM O & NAO GRAVA
						IF !Empty(SB1->B1_XTPSIST) .and. !Empty(SB1->B1_LIQUIDO) .and. !Empty(SB1->B1_XUNMED) //tipo de sistema e apresentação precisam estar preenchidos
							//_cTpSist 	:=  iif(SB1->B1_XTPSIST == "A","SA",iif(SB1->B1_XTPSIST == "F","SF",""))
							_cApresen	:= 	iif(SB1->B1_LIQUIDO == "1","LIQ",iif(SB1->B1_LIQUIDO == "2","PO",""))
							_cMarca 	:=  AllTrim(SB1->B1_XMARCAP) + " " +_cApresen + " & "//NAO REMOVER O & POIS É O GATILHO PARA PREENCHER
							_cPesoLiq	:=  AllTrim(POSICIONE("SX5",1,XFILIAL("SX5")+"ZW"+AllTrim(SB1->B1_XTPEMB),"X5_DESCRI"))
							//_cUnMed		:=	SB1->B1_UM
							FWrite(nHandle,"Marca E Prod Harmonizado atualizada:" + SB1->B1_COD + "-> " +_cMarca + CRLF)
							RecLock("SB1",.F.)
								SB1->B1_XMARCAP := _cMarca
								SB1->B1_XPROHAR := _cMarca  + " " + cValToChar(_cPesoLiq)// + " " + _cUnMed
							SB1->(MsUnlock())
						EndIf 
					ENDIF 
				ENDIF 
			EndIf//PA 
		EndIf//SEEK
		QRY->(dbSkip())
	EndDo

QRY->(dbCloseArea())
SB1->(dbCloseArea())
FWrite(nHandle,"Fim da Gravação Log "+Time()+ CRLF)
FClose(nHandle)

RESET ENVIRONMENT

Return()


Static Function buscaDtLc(cCod)
Local cQuery 	:= ""
Local cRet 		:= ""

	cQuery += " SELECT MIN(D2_EMISSAO) AS DATAVEN " + CRLF
	cQuery += " FROM "+RetSqlName("SD2")+" D2 " + CRLF
	cQuery += " INNER JOIN "+RetSqlName("SF4")+" F4 ON F4_FILIAL = D2_FILIAL AND F4_CODIGO = D2_TES AND F4_DUPLIC = 'S' " + CRLF
	cQuery += " WHERE " + CRLF
	cQuery += " 	D2_COD = '"+cCod+"' AND " + CRLF
	cQuery += " 	D2.D_E_L_E_T_ = '' AND " + CRLF
	cQuery += " 	F4.D_E_L_E_T_ ='' " + CRLF
	
	If (Select ("QRYXSB1")<> 0)
		QRYXSB1->(DbCloseArea())
	EndIf

	TcQuery cQuery New Alias "QRYXSB1" 
	cRet 	:= QRYXSB1->DATAVEN

Return cRet
