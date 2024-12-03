#Include "Totvs.ch"

/*/{Protheus.doc} CH_L_EMP
@author Ihorran Milholi
@since 17/05/2021
@version 1.0

/*/

User Function CH_L_EMP(nParamDias)

Local aSM0  := {}
Local cAlias:= "SM0"

(cAlias)->(dbGoTop())
While !(cAlias)->(Eof())

    aAdd(aSM0,{ Alltrim(SM0->M0_CODIGO)+Alltrim(SM0->M0_CODFIL),;
                SM0->M0_NOMECOM,;
                SM0->M0_CGC,;
                Alltrim(SM0->M0_NOME)+' '+Alltrim(SM0->M0_FILIAL),;
                SM0->M0_INSC,;
                SM0->M0_ENDCOB,;
                SM0->M0_BAIRCOB,;
                SM0->M0_COMPCOB,;
                SM0->M0_CEPCOB,;
                SM0->M0_CIDCOB,;
                SM0->M0_ESTCOB,;
                SM0->M0_TEL})

    //passa o registro
    (cAlias)->(dbSkip())

EndDo

Return aSM0
