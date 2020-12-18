// ----------------------------------------------------------
// This Source Code Form is subject to the terms of the
// Mozilla Public License, v.2.0. If a copy of the MPL
// was not distributed with this file, You can obtain one
// at http://mozilla.org/MPL/2.0/.
// ----------------------------------------------------------
// Codebase: https://github.com/ArKuznetsov/irac/
// ----------------------------------------------------------

Перем Процесс_Ид;            // process
Перем Процесс_АдресСервера;    // host
Перем Процесс_ПортСервера;    // port
Перем Процесс_Свойства;
Перем Процесс_Лицензии;

Перем Кластер_Агент;
Перем Кластер_Владелец;
Перем Процесс_Соединения;

Перем ПараметрыОбъекта;

Перем ПериодОбновления;
Перем МоментАктуальности;

Перем Лог;

// Конструктор
//   
// Параметры:
//   АгентКластера          - АгентКластера            - ссылка на родительский объект агента кластера
//   Кластер                - Кластера                 - ссылка на родительский объект кластера
//   Процесс                - Строка, Соответствие     - идентификатор рабочего процесса или параметры процесса
//
Процедура ПриСозданииОбъекта(АгентКластера, Кластер, Процесс)

	Лог = Служебный.Лог();

	Если НЕ ЗначениеЗаполнено(Процесс) Тогда
		Возврат;
	КонецЕсли;

	Кластер_Агент = АгентКластера;
	Кластер_Владелец = Кластер;
	
	ПараметрыОбъекта = Новый КомандыОбъекта(Кластер_Агент, Перечисления.РежимыАдминистрирования.РабочиеПроцессы);

	Если ТипЗнч(Процесс) = Тип("Соответствие") Тогда
		Процесс_Ид = Процесс["process"];
		ЗаполнитьПараметрыПроцесса(Процесс);
		МоментАктуальности = ТекущаяУниверсальнаяДатаВМиллисекундах();
	Иначе
		Процесс_Ид = Процесс;
		МоментАктуальности = 0;
	КонецЕсли;

	ПериодОбновления = 60000;
	
	Процесс_Соединения      = Новый Соединения(Кластер_Агент, Кластер_Владелец, ЭтотОбъект);
	Процесс_Лицензии        = Новый Лицензии(Кластер_Агент, Кластер_Владелец, ЭтотОбъект);

КонецПроцедуры // ПриСозданииОбъекта()

// Процедура получает данные от сервиса администрирования кластера 1С
// и сохраняет в локальных переменных
//   
// Параметры:
//   ОбновитьПринудительно        - Булево    - Истина - принудительно обновить данные (вызов RAC)
//                                            - Ложь - данные будут получены если истекло время актуальности
//                                                     или данные не были получены ранее
//
Процедура ОбновитьДанные(ОбновитьПринудительно = Ложь) Экспорт

	Если НЕ Служебный.ТребуетсяОбновление(Процесс_Свойства,
	   МоментАктуальности, ПериодОбновления, ОбновитьПринудительно) Тогда
		Возврат;
	КонецЕсли;

	ПараметрыКоманды = Новый Соответствие();
	ПараметрыКоманды.Вставить("СтрокаПодключенияАгента"     , Кластер_Агент.СтрокаПодключения());
	ПараметрыКоманды.Вставить("ПараметрыАвторизацииКластера", Кластер_Владелец.ПараметрыАвторизации());
	ПараметрыКоманды.Вставить("ИдентификаторКластера"       , Кластер_Владелец.Ид());
	ПараметрыКоманды.Вставить("ИдентификаторПроцесса"       , Ид());
	
	ПараметрыОбъекта.УстановитьЗначенияПараметровКоманд(ПараметрыКоманды);

	КодВозврата = ПараметрыОбъекта.ВыполнитьКоманду("Описание");

	Если НЕ КодВозврата = 0 Тогда
		ВызватьИсключение СтрШаблон("Ошибка получения описания рабочего процесса, КодВозврата = %1: %2",
	                                КодВозврата,
	                                Кластер_Агент.ВыводКоманды(Ложь));
	КонецЕсли;
	
	МассивРезультатов = Кластер_Агент.ВыводКоманды();

	Если НЕ ЗначениеЗаполнено(МассивРезультатов) Тогда
		Возврат;
	КонецЕсли;
	
	ЗаполнитьПараметрыПроцесса(МассивРезультатов[0]);

	МоментАктуальности = ТекущаяУниверсальнаяДатаВМиллисекундах();

КонецПроцедуры // ОбновитьДанныеПроцесса()

// Процедура заполняет параметры рабочего процесса кластера 1С
//   
// Параметры:
//   ДанныеЗаполнения        - Соответствие        - данные, из которых будут заполнены параметры рабочего процесса
//   
Процедура ЗаполнитьПараметрыПроцесса(ДанныеЗаполнения)

	Процесс_АдресСервера = ДанныеЗаполнения.Получить("host");
	Процесс_ПортСервера = Число(ДанныеЗаполнения.Получить("port"));

	Служебный.ЗаполнитьСвойстваОбъекта(ЭтотОбъект, Процесс_Свойства, ДанныеЗаполнения);

КонецПроцедуры // ЗаполнитьПараметрыПроцесса()

// Функция возвращает описание параметров объекта
//   
// Возвращаемое значение:
//    КомандыОбъекта - описание параметров объекта,
//
Функция ПараметрыОбъекта() Экспорт

	Возврат ПараметрыОбъекта;

КонецФункции // ПараметрыОбъекта()

// Функция возвращает идентификатор рабочего процесса 1С
//   
// Возвращаемое значение:
//    Строка - идентификатор рабочего процесса 1С
//
Функция Ид() Экспорт

	Возврат Процесс_Ид;

КонецФункции // Ид()

// Функция возвращает адрес сервера рабочего процесса 1С
//   
// Возвращаемое значение:
//    Строка - адрес сервера рабочего процесса 1С
//
Функция АдресСервера() Экспорт
	
	Если Служебный.ТребуетсяОбновление(Процесс_АдресСервера, МоментАктуальности, ПериодОбновления) Тогда
		ОбновитьДанные(Истина);
	КонецЕсли;

	Возврат Процесс_АдресСервера;
	    
КонецФункции // АдресСервера()
	
// Функция возвращает порт рабочего процесса 1С
//   
// Возвращаемое значение:
//    Строка - порт рабочего процесса 1С
//
Функция ПортСервера() Экспорт
	
	Если Служебный.ТребуетсяОбновление(Процесс_ПортСервера, МоментАктуальности, ПериодОбновления) Тогда
		ОбновитьДанные(Истина);
	КонецЕсли;

	Возврат Процесс_ПортСервера;
	    
КонецФункции // ПортСервера()
	
// Функция возвращает значение параметра рабочего процесса 1С
//   
// Параметры:
//   ИмяПоля                 - Строка        - Имя параметра рабочего процесса
//   ОбновитьПринудительно   - Булево        - Истина - обновить список (вызов RAC)
//
// Возвращаемое значение:
//    Произвольный - значение параметра рабочего процесса 1С
//
Функция Получить(ИмяПоля, ОбновитьПринудительно = Ложь) Экспорт
	
	ОбновитьДанные(ОбновитьПринудительно);

	ЗначениеПоля = Неопределено;

	Если НЕ Найти("ИД, PROCESS", ВРег(ИмяПоля)) = 0 Тогда
		ЗначениеПоля = Процесс_Ид;
	ИначеЕсли НЕ Найти("АДРЕССЕРВЕРА, HOST", ВРег(ИмяПоля)) = 0 Тогда
		ЗначениеПоля = Процесс_АдресСервера;
	ИначеЕсли НЕ Найти("ПОРТСЕРВЕРА, PORT", ВРег(ИмяПоля)) = 0 Тогда
		ЗначениеПоля = Процесс_ПортСервера;
	ИначеЕсли НЕ Найти("ЛИЦЕНЗИИ, LICENSES", ВРег(ИмяПоля)) = 0 Тогда
		ЗначениеПоля = Лицензии(ОбновитьПринудительно);
	ИначеЕсли НЕ Найти("СОЕДИНЕНИЯ, CONNECTIONS", ВРег(ИмяПоля)) = 0 Тогда
		ЗначениеПоля = Процесс_Соединения;
	Иначе
		ЗначениеПоля = Процесс_Свойства.Получить(ИмяПоля);
	КонецЕсли;
	
	Если ЗначениеПоля = Неопределено Тогда
	
		ОписаниеПараметра = ПараметрыОбъекта.ОписаниеСвойств("ИмяРАК").Получить(ИмяПоля);

		Если НЕ ОписаниеПараметра = Неопределено Тогда
			ЗначениеПоля = Процесс_Свойства.Получить(ОписаниеПараметра["Имя"]);
		КонецЕсли;
	
	КонецЕсли;

	Возврат ЗначениеПоля;
	    
КонецФункции // Получить()
	
// Функция возвращает список соединений рабочего процесса 1С
//   
// Возвращаемое значение:
//    Соединения - список соединений рабочего процесса 1С
//
Функция Соединения() Экспорт
	
	Возврат Процесс_Соединения;
	
КонецФункции // Соединения()
	
// Функция возвращает список лицензий, выданных рабочим процессом 1С
//   
// Параметры:
//   ОбновитьПринудительно   - Булево    - Истина - обновить данные лицензий (вызов RAC)
//
// Возвращаемое значение:
//    ОбъектыКластера - список лицензий, выданных рабочим процессом 1С
//
Функция Лицензии(ОбновитьПринудительно = Ложь) Экспорт
	
	Если ОбновитьПринудительно Тогда
		Процесс_Лицензии.ОбновитьДанные(ОбновитьПринудительно);
	КонецЕсли;

	Возврат Процесс_Лицензии;
	
КонецФункции // Лицензии()
