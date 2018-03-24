Перем Кластер_Ид;		// cluster
Перем Кластер_Имя;		// name
Перем Кластер_Сервер;	// host
Перем Кластер_Порт;		// port
Перем Кластер_Параметры;

Перем Кластер_Агент;
Перем Кластер_Администратор;
Перем Кластер_Администраторы;
Перем Кластер_Серверы;
Перем Кластер_Менеджеры;
Перем Кластер_Сеансы;
Перем Кластер_Соединения;
Перем Кластер_Блокировки;
Перем Кластер_ИБ;
Перем Кластер_Профили;

Перем ПериодОбновления;
Перем МоментАктуальности;

Перем Лог;

// Конструктор
//   
// Параметры:
//   АгентКластера			- АгентКластера	- ссылка на родительский объект агента кластера
//   Ид						- Строка		- идентификатор кластера
//   Администратор			- Строка		- имя администратора кластера 1С
//   ПарольАдминистратора	- Строка		- пароль администратора кластера 1С
//
Процедура ПриСозданииОбъекта(АгентКластера, Ид, Администратор = "", ПарольАдминистратора = "")

	Если НЕ ЗначениеЗаполнено(Ид) Тогда
		Возврат;
	КонецЕсли;

	Кластер_Агент = АгентКластера;
	Кластер_Ид = Ид;
	
	Если ЗначениеЗаполнено(Администратор) Тогда
		Кластер_Администратор = Новый Структура("Администратор, Пароль", Администратор, ПарольАдминистратора);
	Иначе
		Кластер_Администратор = Неопределено;
	КонецЕсли;

	ПериодОбновления = 60000;
	МоментАктуальности = 0;
	
	Кластер_Администраторы	= Новый АдминистраторыКластера(Кластер_Агент, ЭтотОбъект);
	Кластер_Серверы			= Новый СерверыКластера(Кластер_Агент, ЭтотОбъект);
	Кластер_Менеджеры		= Новый МенеджерыКластера(Кластер_Агент, ЭтотОбъект);
	Кластер_ИБ				= Новый ИнформационныеБазы(Кластер_Агент, ЭтотОбъект);
	Кластер_Сеансы			= Новый Сеансы(Кластер_Агент, ЭтотОбъект);
	Кластер_Соединения		= Новый Соединения(Кластер_Агент, ЭтотОбъект);
	Кластер_Блокировки		= Новый Блокировки(Кластер_Агент, ЭтотОбъект);
	Кластер_Параметры		= Неопределено;

КонецПроцедуры // ПриСозданииОбъекта()

// Процедура получает данные от сервиса администрирования кластера 1С
// и сохраняет в локальных переменных
//   
// Параметры:
//   ОбновитьПринудительно 		- Булево	- Истина - принудительно обновить данные (вызов RAC)
//											- Ложь - данные будут получены если истекло время актуальности
//													или данные не были получены ранее
//   
Процедура ОбновитьДанные(ОбновитьПринудительно = Ложь) Экспорт

	Если НЕ Служебный.ТребуетсяОбновление(Кластер_Параметры,
			МоментАктуальности, ПериодОбновления, ОбновитьПринудительно) Тогда
		Возврат;
	КонецЕсли;

	ПараметрыЗапуска = Новый Массив();
	ПараметрыЗапуска.Добавить(Кластер_Агент.СтрокаПодключения());

	ПараметрыЗапуска.Добавить("cluster");
	ПараметрыЗапуска.Добавить("info");

	ПараметрыЗапуска.Добавить(СтрШаблон("--cluster=%1", Кластер_Ид));

	Служебный.ВыполнитьКоманду(ПараметрыЗапуска);
	
	МассивРезультатов = Служебный.РазобратьВыводКоманды(Служебный.ВыводКоманды());

	ТекОписание = МассивРезультатов[0];

	Кластер_Сервер = ТекОписание.Получить("host");
	Кластер_Порт = ТекОписание.Получить("port");
	Кластер_Имя = ТекОписание.Получить("name");

	ВремКластеры = Новый Кластеры(Кластер_Агент);

	СтруктураПараметров = ВремКластеры.ПолучитьСтруктуруПараметровОбъекта();

	Кластер_Параметры = Новый Структура();

	Для Каждого ТекЭлемент Из СтруктураПараметров Цикл
		ЗначениеПараметра = Служебный.ПолучитьЗначениеИзСтруктуры(ТекОписание,
																  ТекЭлемент.Значение.ИмяПоляРАК,
																  ТекЭлемент.Значение.ЗначениеПоУмолчанию); 
		Кластер_Параметры.Вставить(ТекЭлемент.Ключ, ЗначениеПараметра);
	КонецЦикла;

	МоментАктуальности = ТекущаяУниверсальнаяДатаВМиллисекундах();

КонецПроцедуры // ОбновитьДанные()

// Функция возвращает строку параметров авторизации в кластере 1С
//   
// Возвращаемое значение:
//	Строка - строка параметров авторизации в кластере 1С
//
Функция СтрокаАвторизации() Экспорт
	
	Если НЕ ТипЗнч(Кластер_Администратор)  = Тип("Структура") Тогда
		Возврат "";
	КонецЕсли;

	Если НЕ Кластер_Администратор.Свойство("Администратор") Тогда
		Возврат "";
	КонецЕсли;

	Лог.Отладка("Администратор " + Кластер_Администратор.Администратор);
	Лог.Отладка("Пароль <***>");

	СтрокаАвторизации = "";
	Если Не ПустаяСтрока(Кластер_Администратор.Администратор) Тогда
		СтрокаАвторизации = СтрШаблон("--cluster-user=%1 --cluster-pwd=%2",
									  Кластер_Администратор.Администратор,
									  Кластер_Администратор.Пароль);
	КонецЕсли;
			
	Возврат СтрокаАвторизации;
	
КонецФункции // СтрокаАвторизации()
	
// Процедура устанавливает параметры авторизации в кластере 1С
//   
// Параметры:
//   Администратор 		- Строка	- администратор кластера 1С
//   Пароль			 	- Строка	- пароль администратора кластера 1С
//
Процедура УстановитьАдминистратора(Администратор, Пароль) Экспорт
	
	Кластер_Администратор = Новый Структура("Администратор, Пароль", Администратор, Пароль);
	
КонецПроцедуры // УстановитьАдминистратора()
	
// Функция возвращает идентификатор кластера 1С
//   
// Возвращаемое значение:
//	Строка - идентификатор кластера 1С
//
Функция Ид() Экспорт

	Возврат Кластер_Ид;

КонецФункции // Ид()

// Функция возвращает имя кластера 1С
//   
// Возвращаемое значение:
//	Строка - имя кластера 1С
//
Функция Имя() Экспорт

	Возврат Кластер_Имя;
	
КонецФункции // Имя()

// Функция возвращает адрес сервера кластера 1С
//   
// Возвращаемое значение:
//	Строка - адрес сервера кластера 1С
//
Функция Сервер() Экспорт
	
	Возврат Кластер_Сервер;
		
КонецФункции // Сервер()
	
// Функция возвращает порт сервера кластера 1С
//   
// Возвращаемое значение:
//	Строка - порт сервера кластера 1С
//
Функция Порт() Экспорт
	
	Возврат Кластер_Порт;
		
КонецФункции // Порт()
	
// Функция возвращает значение параметра кластера 1С
//   
// Параметры:
//   ИмяПоля			 	- Строка		- Имя параметра кластера
//   ОбновитьПринудительно 	- Булево		- Истина - обновить список (вызов RAC)
//
// Возвращаемое значение:
//	Произвольный - значение параметра кластера 1С
//
Функция Получить(ИмяПоля, ОбновитьПринудительно = Ложь) Экспорт
	
	ОбновитьДанные(ОбновитьПринудительно);

	Если НЕ Найти(ВРЕг("Ид, cluster"), ВРег(ИмяПоля)) = 0 Тогда
		Возврат Кластер_Ид;
	ИначеЕсли НЕ Найти(ВРЕг("Имя, name"), ВРег(ИмяПоля)) = 0 Тогда
		Возврат Кластер_Имя;
	ИначеЕсли НЕ Найти(ВРЕг("Сервер, host"), ВРег(ИмяПоля)) = 0 Тогда
		Возврат Кластер_Сервер;
	ИначеЕсли НЕ Найти(ВРЕг("Порт, port"), ВРег(ИмяПоля)) = 0 Тогда
		Возврат Кластер_Порт;
	КонецЕсли;
	
	ЗначениеПоля = Кластер_Параметры.Получить(ИмяПоля);

	Если ЗначениеПоля = Неопределено Тогда
		
		ВремКластеры = Новый Кластеры(Кластер_Агент);

		СтруктураПараметров = ВремКластеры.ПолучитьСтруктуруПараметровОбъекта("ИмяПоляРАК");
		
		ОписаниеПараметра = СтруктураПараметров.Получить(ИмяПоля);

		Если НЕ ОписаниеПараметра = Неопределено Тогда
			ЗначениеПоля = Кластер_Параметры.Получить(ОписаниеПараметра["ИмяПараметра"]);
		КонецЕсли;
	КонецЕсли;

	Возврат ЗначениеПоля;
		
КонецФункции // Получить()
	
// Функция возвращает список администраторов кластера 1С
//   
// Возвращаемое значение:
//	Соответствие - список администраторов кластера 1С
//
Функция Администраторы() Экспорт

	Возврат Кластер_Администраторы;

КонецФункции // Администраторы()

// Функция возвращает список серверов кластера 1С
//   
// Возвращаемое значение:
//	СерверыКластера - список серверов кластера 1С
//
Функция Серверы() Экспорт
	
	Возврат Кластер_Серверы;
	
КонецФункции // Серверы()
	
// Функция возвращает список менеджеров кластера 1С
//   
// Возвращаемое значение:
//	МенеджерыКластера - список менеджеров кластера 1С
//
Функция Менеджеры() Экспорт
	
	Возврат Кластер_Менеджеры;
	
КонецФункции // Менеджеры()
	
// Функция возвращает список информационных баз 1С
//   
// Возвращаемое значение:
//	ИнформационныеБазы - список информационных баз 1С
//
Функция ИнформационныеБазы() Экспорт
	
	Возврат Кластер_ИБ;
	
КонецФункции // ИнформационныеБазы()
	
// Функция возвращает список сеансов 1С
//   
// Возвращаемое значение:
//	Сеансы - список сеансов 1С
//
Функция Сеансы() Экспорт
	
	Возврат Кластер_Сеансы;
	
КонецФункции // Сеансы()
	
// Функция возвращает список соединений 1С
//   
// Возвращаемое значение:
//	Сеансы - список соединений 1С
//
Функция Соединения() Экспорт
	
	Возврат Кластер_Соединения;
	
КонецФункции // Соединения()
	
// Функция возвращает список блокировок 1С
//   
// Возвращаемое значение:
//	Сеансы - список блокировок 1С
//
Функция Блокировки() Экспорт
	
	Возврат Кластер_Блокировки;
	
КонецФункции // Блокировки()
	
// Процедура изменяет параметры кластера
//   
// Параметры:
//   Имя				 	- Строка		- новое имя кластера
//   ПараметрыКластера	 	- Структура		- новые параметры кластера
//
Процедура Изменить(Знач Имя = "", Знач ПараметрыКластера = Неопределено) Экспорт

	Если НЕ ТипЗнч(ПараметрыКластера) = Тип("Структура") Тогда
		ПараметрыКластера = Новый Структура();
	КонецЕсли;

	ПараметрыЗапуска = Новый Массив();
	ПараметрыЗапуска.Добавить(Кластер_Агент.СтрокаПодключения());

	ПараметрыЗапуска.Добавить("cluster");
	ПараметрыЗапуска.Добавить("update");

	ПараметрыЗапуска.Добавить(Кластер_Агент.СтрокаАвторизации());

	ПараметрыЗапуска.Добавить(СтрШаблон("--cluster=%1", Кластер_Ид));

	Если ЗначениеЗаполнено(Имя) Тогда
		ПараметрыЗапуска.Добавить(СтрШаблон("--name=%1", Имя));
	КонецЕсли;
	
	ВремКластеры = Новый Кластеры(Кластер_Агент);
	СтруктураПараметров = ВремКластеры.ПолучитьСтруктуруПараметровОбъекта();

	Для Каждого ТекЭлемент Из СтруктураПараметров Цикл
		Если НЕ ПараметрыКластера.Свойство(ТекЭлемент.Ключ) Тогда
			Продолжить;
		КонецЕсли;
		ПараметрыЗапуска.Добавить(СтрШаблон(ТекЭлемент.ПараметрКоманды + "=%1", ПараметрыКластера[ТекЭлемент.Ключ]));
	КонецЦикла;

	Служебный.ВыполнитьКоманду(ПараметрыЗапуска);
	
	Лог.Информация(Служебный.ВыводКоманды());

	Кластер_Параметры = Неопределено;

КонецПроцедуры // Изменить()

Лог = Логирование.ПолучитьЛог("ktb.lib.irac");
