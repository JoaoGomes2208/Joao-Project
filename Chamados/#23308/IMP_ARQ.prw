#include "protheus.ch"
#include "topconn.ch"
#include "fileio.ch" 
#include "TBICONN.ch"
#include "rwmake.ch"
//------------------------------------------------------------------------------------------
/*/{Protheus.doc} ximparq
Permite a manutenção de dados armazenados em alias.

Programa para importar arquivo TXT de uma única tabela
- Dados separados por ponto e virgula (;)
Atualizado para acertar o recklock

@author    TOTVS Developer Studio - Gerado pelo Assistente de Código
@version   1.xx
@since     ${date}
/*/
//------------------------------------------------------------------------------------------
User Function ximparq()
Local cCaminho	:= ""//GetMV("MV_XIMPCAM") //Caminho do Arquivo
Local cTabela	:= ""//GetMV("MV_XIMPTAB") //Tabela de Importação
Local oDlg, oButton, oCombo, cCombo

aItems:= {'SC4-Cab','Z01-Det'}
cCombo:= aItems[2]

DEFINE MSDIALOG oDlg FROM 0,0 TO 300,300 PIXEL TITLE 'Importa Meta'
oCombo:= tComboBox():New(10,10,{|u|if(PCount()>0,cCombo:=u,cCombo)},;
aItems,100,20,oDlg,,{||MsgStop('Mudou item')},,,,.T.,,,,,,,,,'cCombo')
// Botão para fechar a janela
oButton:=tButton():New(30,10,'processa',oDlg,{||oDlg:End()},60,12,,,,.T.)
ACTIVATE MSDIALOG oDlg CENTERED

If cCombo == "SC4-Cab"
	cTabela 	:= "SC4"
	cCaminho 	:= "C:\temp\importacao\CAB.txt"
	Processa( {|| importa( cCaminho, cTabela ) }	, "Aguarde...", "Atualizando Dados SC4...",.F.)
ElseIf cCombo == "Z01-Det"
	cTabela 	:= "Z01"
	cCaminho 	:= "C:\temp\importacao\DET.txt"
	Processa( {|| importa( cCaminho, cTabela ) }	, "Aguarde...", "Atualizando Dados Z01...",.F.)
Else
  		Alert("Processamento Cancelado!")
  		Return
EndIf	

Return


//------------------------------------------------------------------------------------------
Static Function importa( cCaminho, cTabela )
Local aDados	:= {}
Local nHandle	:= 0
Local nLast		:= 0
Local cLine		:= ""
Local nRecno	:= 0
Local cBuffer	:= ""    
Local nI		:= 0
Local nJ		:= 0
Local nContador := 1

nHandle := FT_FUse(cCaminho) 
	If nHandle == -1  
		Alert("Arquivo não pode ser aberto")
		Return
	EndIf
	
FT_FGOTOP()       
nLast := FT_FLastRec() 
ProcRegua(nLast) 

While !FT_FEOF() 
	IncProc("Lendo arquivo texto...") 
	cBuffer := FT_FREADLN()              
	aAdd(aDados,StrTokArr(cBuffer,";"))
	FT_FSKIP() 
EndDo      

FT_FUSE() 

Begin Transaction
		
dbSelectArea(cTabela)

	While Len(aDados) > nContador //.and. nContador <= 5
	 	nContador ++ //Pula Cabecalho primeira passada
	 	RecLock(cTabela, .T.) // Trava registro
	 		IF cTabela == "SC4"
		 		SC4->C4_FILIAL 	:= ""
		 		SC4->C4_PRODUTO	:= PADL(AllTrim(aDados[nContador][1]),6,"0")
		 		SC4->C4_LOCAL	:= AllTrim(aDados[nContador][2])
		 		SC4->C4_DOC		:= ""
		 		SC4->C4_QUANT	:= INT(Val(aDados[nContador][3]))
		 		SC4->C4_VALOR	:= Round(Val(aDados[nContador][4]),4)
		 		SC4->C4_DATA	:= STOD(aDados[nContador][5])
	 		ElseIf cTabela == "Z01"
		 		Z01->Z01_FILIAL := ""
		 		Z01->Z01_MSFIL	:= AllTrim(aDados[nContador][1])
		 		Z01->Z01_PRODUT	:= AllTrim(aDados[nContador][2])
		 		Z01->Z01_LOCAL	:= AllTrim(aDados[nContador][3])
		 		Z01->Z01_DATA	:= StoD((aDados[nContador][4]))
		 		Z01->Z01_REGIAO	:= AllTrim(aDados[nContador][5])
		 		Z01->Z01_VEND	:= ""
		 		Z01->Z01_PERC	:= Round(Val(aDados[nContador][6]),2)
		 		Z01->Z01_QUANT	:= INT(Val(aDados[nContador][7]))
		 		Z01->Z01_VALOR	:= Round(Val(aDados[nContador][8]),4)
	 		EndIf
		MsUnlock(cTabela)// Destrava o registro
	EndDo
End Transaction

	MsgInfo("Processamento Concluído. Total de "+cValToChar(nContador - 1)+" registros adicionados.","Aviso")
		
Return 
//-- fim de arquivo----------------------------------------------------------------------
