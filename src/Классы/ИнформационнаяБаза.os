// ----------------------------------------------------------
// This Source Code Form is subject to the terms of the
// Mozilla Public License, v.2.0. If a copy of the MPL
// was not distributed with this file, You can obtain one
// at http://mozilla.org/MPL/2.0/.
// ----------------------------------------------------------
// Codebase: https://github.com/ArKuznetsov/irac/
// ----------------------------------------------------------

Перем ИБ_Ид;               // (infobase) - идентификатор информационной базы
Перем ИБ_Имя;              // (name) - имя информационной базы
Перем ИБ_Описание;         // (descr) - краткое описание информационной базы
Перем ИБ_ПолноеОписание;   // Истина - получено полное описание; Ложь - сокращенное
Перем ИБ_Сеансы;           // объект-список сеансов этой информационной базы
Перем ИБ_Соединения;       // объект-список соединений этой информационной базы
Перем ИБ_Блокировки;       // объект-список блокировок этой информационной базы
Перем ИБ_Свойства;         // значения свойств этого объекта-информационной базы

Перем Кластер_Агент;       // объект-агент управления кластером
Перем Кластер_Владелец;    // объект-кластер, которому принадлежит текущая информационная база

Перем ПараметрыОбъекта;    // параметры этого объекта управления информационной базой

Перем ПериодОбновления;    // период обновления данных (повторный вызов RAC)
Перем МоментАктуальности;  // последний момент времени обновления данных (время последнего вызова RAC)

Перем Лог;                 // логгер

// Конструктор
//   
// Параметры:
//   АгентКластера          - АгентКластера          - ссылка на родительский объект агента кластера
//   Кластер                - Кластер                - ссылка на родительский объект кластера
//   ИБ                     - Строка, Соответствие   - идентификатор информационной базы в кластере
//                                                     или параметры информационной базы    
//   Администратор          - Строка                 - администратор информационной базы
//   ПарольАдминистратора   - Строка                 - пароль администратора информационной базы
//
Процедура ПриСозданииОбъекта(АгентКластера, Кластер, ИБ, Администратор = "", ПарольАдминистратора = "")

	Лог = Служебный.Лог();

	Если НЕ ЗначениеЗаполнено(ИБ) Тогда
		Возврат;
	КонецЕсли;

	Кластер_Агент = АгентКластера;
	Кластер_Владелец = Кластер;
	
	ПараметрыОбъекта = Новый КомандыОбъекта(Кластер_Агент, Перечисления.РежимыАдминистрирования.ИнформационныеБазы);

	ИБ_ПолноеОписание = Ложь;

	Если ТипЗнч(ИБ) = Тип("Соответствие") Тогда
		ИБ_Ид = ИБ["infobase"];
		ЗаполнитьПараметрыИБ(ИБ);
		МоментАктуальности = ТекущаяУниверсальнаяДатаВМиллисекундах();
	Иначе
		ИБ_Ид = ИБ;
		МоментАктуальности = 0;
	КонецЕсли;

	Если ЗначениеЗаполнено(Администратор) Тогда
		Кластер_Владелец.ДобавитьАдминистратораИБ(ИБ_Ид, Администратор, ПарольАдминистратора);
	КонецЕсли;
	
	ПериодОбновления = Служебный.ПериодОбновленияДанныхОбъекта(ЭтотОбъект);
	
КонецПроцедуры // ПриСозданииОбъекта()

// Процедура получает данные от сервиса администрирования кластера 1С
// и сохраняет в локальных переменных
//   
// Параметры:
//   РежимОбновления           - Число        - 1 - обновить данные принудительно (вызов RAC)
//                                              0 - обновить данные только по таймеру
//                                             -1 - не обновлять данные
//   
Процедура ОбновитьДанные(РежимОбновления = 0) Экспорт

	Если НЕ ТребуетсяОбновление(РежимОбновления) Тогда
		Возврат;
	КонецЕсли;

	ТекОписание = Неопределено;

	Если НЕ РежимОбновления = Перечисления.РежимыОбновленияДанных.ТолькоОсновные Тогда
		Попытка
			ТекОписание = ПолучитьПолноеОписаниеИБ();
		Исключение
			ТекОписание = Неопределено;
		КонецПопытки;
	КонецЕсли;

	Если ТекОписание = Неопределено Тогда
		ИБ_ПолноеОписание = Ложь;
		ТекОписание = ПолучитьОписаниеИБ();
	Иначе
		ИБ_ПолноеОписание = Истина;
	КонецЕсли;
	        
	Если ТекОписание = Неопределено Тогда
		Возврат;
	КонецЕсли;
	
	ЗаполнитьПараметрыИБ(ТекОписание);

	ИБ_Сеансы = Новый Сеансы(Кластер_Агент, Кластер_Владелец, ЭтотОбъект);
	ИБ_Соединения = Новый Соединения(Кластер_Агент, Кластер_Владелец, Неопределено, ЭтотОбъект);
	ИБ_Блокировки = Новый Блокировки(Кластер_Агент, Кластер_Владелец, ЭтотОбъект);

	МоментАктуальности = ТекущаяУниверсальнаяДатаВМиллисекундах();

КонецПроцедуры // ОбновитьДанные()

// Функция признак необходимости обновления данных
//   
// Параметры:
//   РежимОбновления           - Число        - 1 - обновить данные принудительно (вызов RAC)
//                                              0 - обновить данные только по таймеру
//                                             -1 - не обновлять данные
//
// Возвращаемое значение:
//    Булево - Истина - требуется обновитьданные
//
Функция ТребуетсяОбновление(РежимОбновления = 0) Экспорт

	Возврат Служебный.ТребуетсяОбновление(ИБ_Свойства, МоментАктуальности,
	                                      ПериодОбновления, РежимОбновления);

КонецФункции // ТребуетсяОбновление()

// Процедура заполняет параметры информационной базы
//   
// Параметры:
//   ДанныеЗаполнения        - Соответствие        - данные, из которых будут заполнены параметры ИБ
//   
Процедура ЗаполнитьПараметрыИБ(ДанныеЗаполнения)

	ИБ_Имя = ДанныеЗаполнения.Получить("name");
	ИБ_Описание = ДанныеЗаполнения.Получить("descr");

	Служебный.ЗаполнитьСвойстваОбъекта(ЭтотОбъект, ИБ_Свойства, ДанныеЗаполнения);

КонецПроцедуры // ЗаполнитьПараметрыИБ()

// Функция возвращает описание параметров объекта
//   
// Возвращаемое значение:
//    КомандыОбъекта - описание параметров объекта,
//
Функция ПараметрыОбъекта() Экспорт

	Возврат ПараметрыОбъекта;

КонецФункции // ПараметрыОбъекта()

// Функция возвращает полное описание информационной базы 1С
//
// Возвращаемое значение:
//    Соответствие - полное описание информационной базы 1С
//   
Функция ПолучитьПолноеОписаниеИБ()

	ПараметрыКоманды = Новый Соответствие();
	ПараметрыКоманды.Вставить("СтрокаПодключенияАгента"     , Кластер_Агент.СтрокаПодключения());
	ПараметрыКоманды.Вставить("ИдентификаторКластера"       , Кластер_Владелец.Ид());
	ПараметрыКоманды.Вставить("ПараметрыАвторизацииКластера", Кластер_Владелец.ПараметрыАвторизации());
	ПараметрыКоманды.Вставить("ИдентификаторИБ"             , Ид());
	ПараметрыКоманды.Вставить("ПараметрыАвторизацииИБ"      , ПараметрыАвторизации());

	ПараметрыОбъекта.УстановитьЗначенияПараметровКоманд(ПараметрыКоманды);
	    
	КодВозврата = ПараметрыОбъекта.ВыполнитьКоманду("ПолноеОписание");
	
	Если НЕ КодВозврата = 0 Тогда
		Если Найти(Кластер_Агент.ВыводКоманды(Ложь), "Недостаточно прав пользователя") = 0 Тогда
			ВызватьИсключение Кластер_Агент.ВыводКоманды(Ложь);
		Иначе
			ВызватьИсключение СтрШаблон("Ошибка получения полного описания информационной базы ""%1"": %2",
			                            Имя(),
			                            Кластер_Агент.ВыводКоманды(Ложь));
		КонецЕсли;
	КонецЕсли;
	    
	МассивРезультатов = Кластер_Агент.ВыводКоманды();

	Если НЕ ЗначениеЗаполнено(МассивРезультатов) Тогда
		Возврат Неопределено;
	КонецЕсли;

	Возврат МассивРезультатов[0];

КонецФункции // ПолучитьПолноеОписаниеИБ()

// Функция возвращает сокращенное описание информационной базы 1С
//
// Возвращаемое значение:
//    Соответствие - сокращенное описание информационной базы 1С
//   
Функция ПолучитьОписаниеИБ()

	ПараметрыКоманды = Новый Соответствие();
	ПараметрыКоманды.Вставить("СтрокаПодключенияАгента"     , Кластер_Агент.СтрокаПодключения());
	ПараметрыКоманды.Вставить("ИдентификаторКластера"       , Кластер_Владелец.Ид());
	ПараметрыКоманды.Вставить("ПараметрыАвторизацииКластера", Кластер_Владелец.ПараметрыАвторизации());
	ПараметрыКоманды.Вставить("ИдентификаторИБ"             , Ид());

	ПараметрыОбъекта.УстановитьЗначенияПараметровКоманд(ПараметрыКоманды);

	КодВозврата = ПараметрыОбъекта.ВыполнитьКоманду("Описание");

	Если НЕ КодВозврата = 0 Тогда
		ВызватьИсключение СтрШаблон("Ошибка получения описания информационной базы ""%1"": %2",
	                                Имя(),
	                                Кластер_Агент.ВыводКоманды(Ложь));
	КонецЕсли;

	МассивРезультатов = Кластер_Агент.ВыводКоманды();

	Если НЕ ЗначениеЗаполнено(МассивРезультатов) Тогда
		Возврат Неопределено;
	КонецЕсли;
	
	Возврат МассивРезультатов[0];

КонецФункции // ПолучитьОписаниеИБ()

// Функция возвращает структуру параметров авторизации для информационной базы 1С
//   
// Возвращаемое значение:
//    Строка - структура параметров авторизации для информационной базы 1С
//
Функция ПараметрыАвторизации() Экспорт
	
	Возврат Служебный.ПараметрыАвторизации(Перечисления.РежимыАдминистрирования.ИнформационныеБазы,
	                                       Кластер_Агент.ПолучитьАдминистратораИБ(Ид()));

КонецФункции // ПараметрыАвторизации()

// Функция возвращает строку параметров авторизации для информационной базы 1С
//   
// Возвращаемое значение:
//    Строка - строка параметров авторизации для информационной базы 1С
//
Функция СтрокаАвторизации() Экспорт
	
	Возврат Служебный.СтрокаАвторизации(ПараметрыАвторизации());
	
КонецФункции // СтрокаАвторизации()

// Процедура устанавливает параметры авторизации для информационной базы 1С
//   
// Параметры:
//   Администратор         - Строка    - администратор информационной базы 1С
//   Пароль                - Строка    - пароль администратора информационной базы 1С
//
Процедура УстановитьАдминистратора(Администратор, Пароль) Экспорт

	Кластер_Агент.ДобавитьАдминистратораИБ(Ид(), Администратор, Пароль);

КонецПроцедуры // УстановитьАдминистратора()

// Функция возвращает идентификатор информационной базы 1С
//   
// Возвращаемое значение:
//    Строка - идентификатор информационной базы 1С
//
Функция Ид() Экспорт

	Возврат ИБ_Ид;

КонецФункции // Ид()

// Функция возвращает имя информационной базы 1С
//   
// Возвращаемое значение:
//    Строка - имя информационной базы 1С
//
Функция Имя() Экспорт

	Если Служебный.ТребуетсяОбновление(ИБ_Имя, МоментАктуальности, ПериодОбновления) Тогда
		ТекОписание = ПолучитьОписаниеИБ();
		ИБ_Имя = ТекОписание.Получить("name");
	КонецЕсли;

	Возврат ИБ_Имя;
	
КонецФункции // Имя()

// Функция возвращает описание информационной базы 1С
//   
// Возвращаемое значение:
//    Строка - описание информационной базы 1С
//
Функция Описание() Экспорт

	Если Служебный.ТребуетсяОбновление(ИБ_Описание, МоментАктуальности, ПериодОбновления) Тогда
		ТекОписание = ПолучитьОписаниеИБ();
		ИБ_Описание = ТекОписание.Получить("descr");
	КонецЕсли;

	Возврат ИБ_Описание;
	
КонецФункции // Описание()

// Функция возвращает признак доступности полного описания информационной базы 1С
//   
// Возвращаемое значение:
//    Булево - Истина - доступно полное описание; Ложь - доступно сокращенное описание
//
Функция ПолноеОписание() Экспорт

	Если Служебный.ТребуетсяОбновление(ИБ_ПолноеОписание, МоментАктуальности, ПериодОбновления) Тогда
		ОбновитьДанные(Перечисления.РежимыОбновленияДанных.Принудительно);
	КонецЕсли;

	Возврат ИБ_ПолноеОписание;
	
КонецФункции // ПолноеОписание()

// Функция возвращает сеансы информационной базы 1С
//   
// Возвращаемое значение:
//    Сеансы - сеансы информационной базы 1С
//
Функция Сеансы() Экспорт
	
	Если Служебный.ТребуетсяОбновление(ИБ_Сеансы, МоментАктуальности, ПериодОбновления) Тогда
		ОбновитьДанные(Перечисления.РежимыОбновленияДанных.Принудительно);
	КонецЕсли;

	Возврат ИБ_Сеансы;
	    
КонецФункции // Сеансы()

// Функция возвращает соединения информационной базы 1С
//   
// Возвращаемое значение:
//    Соединения - соединения информационной базы 1С
//
Функция Соединения() Экспорт
	
	Если Служебный.ТребуетсяОбновление(ИБ_Соединения, МоментАктуальности, ПериодОбновления) Тогда
		ОбновитьДанные(Перечисления.РежимыОбновленияДанных.Принудительно);
	КонецЕсли;

	Возврат ИБ_Соединения;
	    
КонецФункции // Соединения()

// Функция возвращает блокировки информационной базы 1С
//   
// Возвращаемое значение:
//    Блокировки - блокировки информационной базы 1С
//
Функция Блокировки() Экспорт
	
	Если Служебный.ТребуетсяОбновление(ИБ_Блокировки, МоментАктуальности, ПериодОбновления) Тогда
		ОбновитьДанные(Перечисления.РежимыОбновленияДанных.Принудительно);
	КонецЕсли;

	Возврат ИБ_Блокировки;
	    
КонецФункции // Блокировки()

// Функция возвращает значение параметра информационной базы 1С
//   
// Параметры:
//   ИмяПоля                 - Строка        - Имя параметра информационной базы
//   РежимОбновления         - Число         - 1 - обновить данные принудительно (вызов RAC)
//                                             0 - обновить данные только по таймеру
//                                            -1 - не обновлять данные
//
// Возвращаемое значение:
//    Произвольный - значение параметра кластера 1С
//
Функция Получить(ИмяПоля, РежимОбновления = 0) Экспорт
	
	ОбновитьДанные(РежимОбновления);

	ЗначениеПоля = Неопределено;

	Если НЕ Найти("ИД, INFOBASE", ВРег(ИмяПоля)) = 0 Тогда
		ЗначениеПоля = ИБ_Ид;
	ИначеЕсли НЕ Найти("ИМЯ, NAME", ВРег(ИмяПоля)) = 0 Тогда
		ЗначениеПоля = ИБ_Имя;
	ИначеЕсли НЕ Найти("ОПИСАНИЕ, DESCK", ВРег(ИмяПоля)) = 0 Тогда
		ЗначениеПоля = ИБ_Описание;
	ИначеЕсли НЕ Найти("ПОЛНОЕОПИСАНИЕ", ВРег(ИмяПоля)) = 0 Тогда
		ЗначениеПоля = ИБ_ПолноеОписание;
	ИначеЕсли НЕ Найти("СЕАНСЫ, SESSIONS", ВРег(ИмяПоля)) = 0 Тогда
		ЗначениеПоля = ИБ_Сеансы;
	ИначеЕсли НЕ Найти("СОЕДИНЕНИЯ, CONNECTIONS", ВРег(ИмяПоля)) = 0 Тогда
		ЗначениеПоля = ИБ_Соединения;
	ИначеЕсли НЕ Найти("БЛОКИРОВКИ, LOCKS", ВРег(ИмяПоля)) = 0 Тогда
		ЗначениеПоля = ИБ_Блокировки;
	Иначе
		ЗначениеПоля = ИБ_Свойства.Получить(ИмяПоля);
	КонецЕсли;
	
	Если ЗначениеПоля = Неопределено Тогда
	
		ОписаниеПараметра = ПараметрыОбъекта.ОписаниеСвойств("ИмяРАК").Получить(ИмяПоля);

		Если НЕ ОписаниеПараметра = Неопределено Тогда
			ЗначениеПоля = ИБ_Свойства.Получить(ОписаниеПараметра["Имя"]);
		КонецЕсли;
	
	КонецЕсли;

	Возврат ЗначениеПоля;
	
КонецФункции // Получить()
	
// Процедура изменяет параметры информационной базы
//   
// Параметры:
//   ПараметрыИБ         - Структура        - новые параметры информационной базы
//
Процедура Изменить(Знач ПараметрыИБ = Неопределено) Экспорт

	Если НЕ ТипЗнч(ПараметрыИБ) = Тип("Структура") Тогда
		ПараметрыИБ = Новый Структура();
	КонецЕсли;

	ПараметрыКоманды = Новый Соответствие();
	ПараметрыКоманды.Вставить("СтрокаПодключенияАгента"     , Кластер_Агент.СтрокаПодключения());
	ПараметрыКоманды.Вставить("ИдентификаторКластера"       , Кластер_Владелец.Ид());
	ПараметрыКоманды.Вставить("ПараметрыАвторизацииКластера", Кластер_Владелец.ПараметрыАвторизации());
	
	ПараметрыКоманды.Вставить("ИдентификаторИБ"            , Ид());
	ПараметрыКоманды.Вставить("ПараметрыАвторизацииИБ"     , ПараметрыАвторизации());

	Для Каждого ТекЭлемент Из ПараметрыИБ Цикл
		ПараметрыКоманды.Вставить(ТекЭлемент.Ключ, ТекЭлемент.Значение);
	КонецЦикла;

	ПараметрыОбъекта.УстановитьЗначенияПараметровКоманд(ПараметрыКоманды);

	КодВозврата = ПараметрыОбъекта.ВыполнитьКоманду("Изменить");

	Если НЕ КодВозврата = 0 Тогда
		ВызватьИсключение СтрШаблон("Ошибка изменения информационной базы ""%1"": %2",
	                                Имя(),
	                                Кластер_Агент.ВыводКоманды(Ложь));
	КонецЕсли;

	Лог.Отладка(Кластер_Агент.ВыводКоманды(Ложь));

	ОбновитьДанные(Перечисления.РежимыОбновленияДанных.Принудительно);

КонецПроцедуры // Изменить()

// Процедура удаляет информационную базу
//   
// Параметры:
//   ДействияСБазойСУБД    - Строка      - "drop" - удалить базу данных; "clear" - очистить базу данных;
//                                         иначе оставить базу данных как есть
//
Процедура Удалить(ДействияСБазойСУБД = "") Экспорт
	
	ПараметрыКоманды = Новый Соответствие();
	ПараметрыКоманды.Вставить("СтрокаПодключенияАгента"     , Кластер_Агент.СтрокаПодключения());
	ПараметрыКоманды.Вставить("ИдентификаторКластера"       , Кластер_Владелец.Ид());
	ПараметрыКоманды.Вставить("ПараметрыАвторизацииКластера", Кластер_Владелец.ПараметрыАвторизации());
	
	ПараметрыКоманды.Вставить("ИдентификаторИБ"             , Ид());
	ПараметрыКоманды.Вставить("ПараметрыАвторизацииИБ"      , ПараметрыАвторизации());

	Если ДействияСБазойСУБД = Перечисления.ДействияСБазойСУБДПриУдалении.Очистить Тогда
		ПараметрыКоманды.Вставить("ОчиститьБД", Истина);
	КонецЕсли;
	Если ДействияСБазойСУБД = Перечисления.ДействияСБазойСУБДПриУдалении.Удалить Тогда
		ПараметрыКоманды.Вставить("УдалитьБД", Истина);
	КонецЕсли;
	
	ПараметрыОбъекта.УстановитьЗначенияПараметровКоманд(ПараметрыКоманды);

	КодВозврата = ПараметрыОбъекта.ВыполнитьКоманду("Удалить");

	Если НЕ КодВозврата = 0 Тогда
		ВызватьИсключение СтрШаблон("Ошибка удаления информационной базы ""%1"": %2",
	                                Имя(),
	                                Кластер_Агент.ВыводКоманды(Ложь));
	КонецЕсли;
	
	Лог.Отладка(Кластер_Агент.ВыводКоманды(Ложь));

КонецПроцедуры // Удалить()
