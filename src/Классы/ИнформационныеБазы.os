// ----------------------------------------------------------
// This Source Code Form is subject to the terms of the
// Mozilla Public License, v.2.0. If a copy of the MPL
// was not distributed with this file, You can obtain one
// at http://mozilla.org/MPL/2.0/.
// ----------------------------------------------------------
// Codebase: https://github.com/ArKuznetsov/irac/
// ----------------------------------------------------------

Перем Кластер_Агент;
Перем Кластер_Владелец;
Перем ПараметрыОбъекта;
Перем Элементы;

Перем Лог;

// Конструктор
//   
// Параметры:
//   АгентКластера      - АгентКластера  - ссылка на родительский объект агента кластера
//   Кластер            - Кластер        - ссылка на родительский объект кластера
//
Процедура ПриСозданииОбъекта(АгентКластера, Кластер)

	Лог = Служебный.Лог();

	Кластер_Агент = АгентКластера;
	Кластер_Владелец = Кластер;

	ПараметрыОбъекта = Новый КомандыОбъекта(Кластер_Агент, Перечисления.РежимыАдминистрирования.ИнформационныеБазы);

	Элементы = Новый ОбъектыКластера(ЭтотОбъект);

КонецПроцедуры

// Процедура получает список информационных баз от утилиты администрирования кластера 1С
// и сохраняет в локальных переменных
//   
// Параметры:
//   ОбновитьПринудительно         - Булево    - Истина - принудительно обновить данные (вызов RAC)
//                                            - Ложь - данные будут получены если истекло время актуальности
//                                                    или данные не были получены ранее
//   
Процедура ОбновитьДанные(ОбновитьПринудительно = Ложь) Экспорт

	Если НЕ Элементы.ТребуетсяОбновление(ОбновитьПринудительно) Тогда
		Возврат;
	КонецЕсли;

	ПараметрыКоманды = Новый Соответствие();
	ПараметрыКоманды.Вставить("СтрокаПодключенияАгента"     , Кластер_Агент.СтрокаПодключения());
	ПараметрыКоманды.Вставить("ИдентификаторКластера"       , Кластер_Владелец.Ид());
	ПараметрыКоманды.Вставить("ПараметрыАвторизацииКластера", Кластер_Владелец.ПараметрыАвторизации());
	
	ПараметрыОбъекта.УстановитьЗначенияПараметровКоманд(ПараметрыКоманды);

	КодВозврата = ПараметрыОбъекта.ВыполнитьКоманду("Список");
	
	Если НЕ КодВозврата = 0 Тогда
		ВызватьИсключение СтрШаблон("Ошибка получения списка информационных баз, КодВозврата = %1: %2",
	                                КодВозврата,
	                                Кластер_Агент.ВыводКоманды(Ложь));
	КонецЕсли;
	
	МассивРезультатов = Кластер_Агент.ВыводКоманды();

	МассивИБ = Новый Массив();
	Для Каждого ТекОписание Из МассивРезультатов Цикл
		МассивИБ.Добавить(Новый ИнформационнаяБаза(Кластер_Агент, Кластер_Владелец, ТекОписание));
	КонецЦикла;

	Элементы.Заполнить(МассивИБ);

	Элементы.УстановитьАктуальность();

КонецПроцедуры // ОбновитьДанные()

// Функция возвращает коллекцию параметров объекта
//   
// Параметры:
//   ИмяПоляКлюча         - Строка    - имя поля, значение которого будет использовано
//                                      в качестве ключа возвращаемого соответствия
//   
// Возвращаемое значение:
//    Соответствие - коллекция параметров объекта, для получения/изменения значений
//
Функция ПараметрыОбъекта(ИмяПоляКлюча = "Имя") Экспорт

	Возврат ПараметрыОбъекта.ОписаниеСвойств(ИмяПоляКлюча);

КонецФункции // ПараметрыОбъекта()

// Функция возвращает список информационных баз
//   
// Параметры:
//   Отбор                     - Структура    - Структура отбора информационных баз (<поле>:<значение>)
//   ОбновитьПринудительно     - Булево       - Истина - принудительно обновить данные (вызов RAC)
//   ЭлементыКакСоответствия   - Булево,      - Истина - элементы результата будут преобразованы в соответствия
//                               Строка         с именами свойств в качестве ключей
//                                              <Имя поля> - элементы результата будут преобразованы в соответствия
//                                              со значением указанного поля в качестве ключей ("Имя"|"ИмяРАК")
//                                              Ложь - (по умолчанию) элементы будут возвращены как есть
//
// Возвращаемое значение:
//    Массив - список информационных баз
//
Функция Список(Отбор = Неопределено, ОбновитьПринудительно = Ложь, ЭлементыКакСоответствия = Ложь) Экспорт

	Возврат Элементы.Список(Отбор, ОбновитьПринудительно, ЭлементыКакСоответствия);

КонецФункции // Список()

// Функция возвращает список информационных баз
//   
// Параметры:
//   ПоляИерархии              - Строка       - Поля для построения иерархии списка информационных баз, разделенные ","
//   ОбновитьПринудительно     - Булево       - Истина - обновить список (вызов RAC)
//   ЭлементыКакСоответствия   - Булево,      - Истина - элементы результата будут преобразованы в соответствия
//                               Строка         с именами свойств в качестве ключей
//                                              <Имя поля> - элементы результата будут преобразованы в соответствия
//                                              со значением указанного поля в качестве ключей ("Имя"|"ИмяРАК")
//                                              Ложь - (по умолчанию) элементы будут возвращены как есть
//
// Возвращаемое значение:
//    Соответствие - список информационных баз
//        <имя поля объекта>    - Массив(Соответствие),    - список информационных баз
//                                Соответствие               или следующий уровень
//
Функция ИерархическийСписок(Знач ПоляИерархии, ОбновитьПринудительно = Ложь, ЭлементыКакСоответствия = Ложь) Экспорт

	Возврат Элементы.ИерархическийСписок(ПоляИерархии, ОбновитьПринудительно, ЭлементыКакСоответствия);

КонецФункции // ИерархическийСписок()

// Функция возвращает количество информационных баз в списке
//   
// Возвращаемое значение:
//    Число - количество информационных баз
//
Функция Количество() Экспорт

	Если Элементы = Неопределено Тогда
		Возврат 0;
	КонецЕсли;
	
	Возврат Элементы.Количество();

КонецФункции // Количество()

// Функция возвращает описание информационной базы 1С
//   
// Параметры:
//   ИмяИлиИд                - Строка    - Имя или идентификатор информационной базы 1С
//   ОбновитьПринудительно   - Булево    - Истина - принудительно обновить данные (вызов RAC)
//   КакСоответствие         - Булево    - Истина - результат будет преобразован в соответствие
//
// Возвращаемое значение:
//    Соответствие - описание информационной базы 1С
//
Функция Получить(Знач ИмяИлиИд, Знач ОбновитьПринудительно = Ложь, КакСоответствие = Ложь) Экспорт

	Отбор = Новый Соответствие();

	Если Служебный.ЭтоGUID(ИмяИлиИд) Тогда
		Отбор.Вставить("infobase", ИмяИлиИд);
	Иначе
		Отбор.Вставить("name", ИмяИлиИд);
	КонецЕсли;

	СписокИБ = Элементы.Список(Отбор, ОбновитьПринудительно, КакСоответствие);
	
	Если НЕ ЗначениеЗаполнено(СписокИБ) Тогда
		Возврат Неопределено;
	КонецЕсли;
	
	Возврат СписокИБ[0];

КонецФункции // Получить()

// Процедура добавляет новую информационную базу
//   
// Параметры:
//   Имя                 - Строка        - имя информационной базы
//   Локализация         - Строка        - локализация базы
//   СоздатьБазуСУБД     - Булево        - Истина - создать базу данных на сервере СУБД; Ложь - не создавать
//   ПараметрыИБ         - Структура        - параметры информационной базы
//
Процедура Добавить(Имя, Локализация = "ru_RU", СоздатьБазуСУБД = Ложь, ПараметрыИБ = Неопределено) Экспорт

	Если НЕ ТипЗнч(ПараметрыИБ) = Тип("Структура") Тогда
		ПараметрыИБ = Новый Структура();
	КонецЕсли;

	ПараметрыКоманды = Новый Соответствие();
	ПараметрыКоманды.Вставить("СтрокаПодключенияАгента"     , Кластер_Агент.СтрокаПодключения());
	ПараметрыКоманды.Вставить("ИдентификаторКластера"       , Кластер_Владелец.Ид());
	ПараметрыКоманды.Вставить("ПараметрыАвторизацииКластера", Кластер_Владелец.ПараметрыАвторизации());
	
	ПараметрыКоманды.Вставить("Имя"            , Имя);
	ПараметрыКоманды.Вставить("Локализация"    , Локализация);
	ПараметрыКоманды.Вставить("СоздатьБазуСУБД", СоздатьБазуСУБД);

	Для Каждого ТекЭлемент Из ПараметрыИБ Цикл
		ПараметрыКоманды.Вставить(ТекЭлемент.Ключ, ТекЭлемент.Значение);
	КонецЦикла;

	ПараметрыОбъекта.УстановитьЗначенияПараметровКоманд(ПараметрыКоманды);

	КодВозврата = ПараметрыОбъекта.ВыполнитьКоманду("Добавить");

	Если НЕ КодВозврата = 0 Тогда
		ВызватьИсключение СтрШаблон("Ошибка добавления информационной базы ""%1"": %2",
	                                Имя,
	                                Кластер_Агент.ВыводКоманды(Ложь));
	КонецЕсли;
	
	Лог.Отладка(Кластер_Агент.ВыводКоманды(Ложь));

	ОбновитьДанные(Истина);

КонецПроцедуры // Добавить()

// Процедура удаляет информационную базу
//   
// Параметры:
//   Имя                 - Строка        - имя информационной базы
//   ДействияСБазойСУБД  - Строка        - "drop" - удалить базу данных; "clear" - очистить базу данных;
//                                         иначе оставить базу данных как есть
//
Процедура Удалить(Имя, ДействияСБазойСУБД = "") Экспорт
	
	ИБ = Получить(Имя);

	Если ИБ = Неопределено Тогда
		Возврат;
	КонецЕсли;

	ИБ.Удалить(ДействияСБазойСУБД);

	ОбновитьДанные(Истина);

КонецПроцедуры // Удалить()
