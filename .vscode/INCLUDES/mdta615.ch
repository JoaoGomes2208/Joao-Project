#ifdef SPANISH
	#define STR0001 "Buscar"
	#define STR0002 "Visualizar"
	#define STR0003 "Incluir"
	#define STR0004 "Modificar"
	#define STR0005 "Borrar"
	#define STR0006 "Plan de Accion"
	#define STR0007 "Plan de Accion"
	#define STR0008 "Leyenda"
	#define STR0009 "Vincular documento"
	#define STR0010 "Vin.Doc."
	#define STR0011 "Atencion"
	#define STR0012 "�Que desea realizar?"
	#define STR0013 "Vincular un documento"
	#define STR0014 "Visualizar documento vinculado"
	#define STR0015 "Borrar documento vinculado"
	#define STR0016 "No existe documento asociado a este plan de accion."
	#define STR0017 "NO CONFORMIDAD"
	#define STR0018 "Plan de accion pendiente"
	#define STR0019 "Plan de accion finalizado"
	#define STR0020 "Clientes"
	#define STR0021 "Planes de Accion"
	#define STR0022 "La fecha de Implementacion del Plan de Accion no puede ser posterior a la fecha actual."
	#define STR0023 "Informar una fecha anterior a la actual."
	#define STR0024 "La fecha de inicio no puede superior a la final."
	#define STR0025 "Informe las fechas"
	#define STR0026 "Previstas"
	#define STR0027 "Reales"
	#define STR0028 "para que la fecha de inicio sea menor a la final."
	#define STR0029 "El porcentaje de conclusion no puede ser menor al 0% ni exceder el 100%."
	#define STR0030 "Informar un valor entre 0 y 100."
#else
	#ifdef ENGLISH
		#define STR0001 "Search"
		#define STR0002 "View"
		#define STR0003 "Insert"
		#define STR0004 "Edit"
		#define STR0005 "Delete"
		#define STR0006 "Action Plan"
		#define STR0007 "Action Plan"
		#define STR0008 "Caption"
		#define STR0009 "Relate document "
		#define STR0010 "Rel.Doc."
		#define STR0011 "Attention"
		#define STR0012 "What will you do? "
		#define STR0013 "Relate a document "
		#define STR0014 "View related document "
		#define STR0015 "Delete related document "
		#define STR0016 "No document associated to this action plan. "
		#define STR0017 "NON-CONFORMANCE "
		#define STR0018 "Action plan open "
		#define STR0019 "Action plan finished "
		#define STR0020 "Customers"
		#define STR0021 "Action plans"
		#define STR0022 "Action Plan Implantation Date cannot be after current date."
		#define STR0023 "Enter a date earlier than the current one."
		#define STR0024 "Start Date cannot be later than end date."
		#define STR0025 "Enter dates"
		#define STR0026 "Anticipated"
		#define STR0027 "Actual"
		#define STR0028 "so that start date is earlier than end date."
		#define STR0029 "The Conclusion Percentage can neither be smaller than 0% nor greater than 100%."
		#define STR0030 "Enter a value between 0 and 100."
	#else
		#define STR0001 "Pesquisar"
		#define STR0002 "Visualizar"
		#define STR0003 "Incluir"
		#define STR0004 "Alterar"
		#define STR0005 "Excluir"
		#define STR0006 If( cPaisLoc $ "ANG|PTG", "Plano De Ac��o", "Plano de Acao" )
		#define STR0007 If( cPaisLoc $ "ANG|PTG", "Plano De Ac��o", "Plano de A��o" )
		#define STR0008 "Legenda"
		#define STR0009 "Relacionar documento"
		#define STR0010 If( cPaisLoc $ "ANG|PTG", "Rel.doc.", "Rel.Doc." )
		#define STR0011 "Aten��o"
		#define STR0012 "O que deseja fazer ?"
		#define STR0013 "Relacionar um documento"
		#define STR0014 "Visualizar documento relacionado"
		#define STR0015 "Apagar documento relacionado"
		#define STR0016 If( cPaisLoc $ "ANG|PTG", "N�o existe documento associado a este plano de ac��o.", "N�o existe documento associado a este plano de a��o." )
		#define STR0017 If( cPaisLoc $ "ANG|PTG", "N�o conformidade", "N�O CONFORMIDADE" )
		#define STR0018 If( cPaisLoc $ "ANG|PTG", "Plano de ac��o aberto", "Plano de a��o aberto" )
		#define STR0019 If( cPaisLoc $ "ANG|PTG", "Plano de ac��o finalizado", "Plano de a��o finalizado" )
		#define STR0020 "Clientes"
		#define STR0021 If( cPaisLoc $ "ANG|PTG", "Planos de ac��o", "Planos de A��o" )
		#define STR0022 "Data de Implanta��o do Plano de A��o n�o pode ser posterior a data atual."
		#define STR0023 "Informar uma data anterior � atual."
		#define STR0024 "Data in�cio n�o pode ser maior que a fim."
		#define STR0025 "Informe as datas"
		#define STR0026 "Previstas"
		#define STR0027 "Reais"
		#define STR0028 "de forma que a data in�cio seja menor que a fim."
		#define STR0029 "O Percentual de Conclus�o n�o pode ser menor que 0% nem ultrapassar 100%."
		#define STR0030 "Informar um valor entre 0 e 100."
	#endif
#endif