Перем ТипЭлементов;
Перем Кластер_Агент;
Перем Кластер_Владелец;
Перем Профиль_Владелец;
Перем Элементы;

Перем ПараметрыЭлементов;

Перем МоментАктуальности;
Перем ПериодОбновления;

Перем Лог;

Процедура ПриСозданииОбъекта(Агент, Кластер, Профиль, Тип)

	Элементы = Неопределено;

	Кластер_Агент = Агент;
	Кластер_Владелец = Кластер;
	Профиль_Владелец = Профиль;

	ТипЭлементов = Тип;

	ПараметрыЭлементов = Новый ПараметрыОбъекта("profile." + ТипЭлементов);

	ПериодОбновления = 60000;
	МоментАктуальности = 0;

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

	Если НЕ ТребуетсяОбновление(ОбновитьПринудительно) Тогда
		Возврат;
	КонецЕсли;

	ПараметрыЗапуска = Новый Массив();
	ПараметрыЗапуска.Добавить(Кластер_Агент.СтрокаПодключения());

	ПараметрыЗапуска.Добавить("profile");
	ПараметрыЗапуска.Добавить("acl");
	ПараметрыЗапуска.Добавить(ТипЭлементов);
	ПараметрыЗапуска.Добавить("list");

	ПараметрыЗапуска.Добавить(СтрШаблон("--name=%1", Профиль_Владелец.Имя()));
	ПараметрыЗапуска.Добавить(СтрШаблон("--cluster=%1", Кластер_Владелец.Ид()));
	ПараметрыЗапуска.Добавить(Кластер_Владелец.СтрокаАвторизации());

	Кластер_Агент.ВыполнитьКоманду(ПараметрыЗапуска);
	
	Элементы = Кластер_Агент.ВыводКоманды();

	МоментАктуальности = ТекущаяУниверсальнаяДатаВМиллисекундах();

КонецПроцедуры // ОбновитьДанные()

// Функция признак необходимости обновления данных
//   
// Параметры:
//   ОбновитьПринудительно 	- Булево		- Истина - принудительно обновить данные (вызов RAC)
//
// Возвращаемое значение:
//	Булево - Истина - требуется обновитьданные
//
Функция ТребуетсяОбновление(ОбновитьПринудительно = Ложь) Экспорт

	Возврат (ОбновитьПринудительно
		ИЛИ Элементы = Неопределено
		ИЛИ (ПериодОбновления < (ТекущаяУниверсальнаяДатаВМиллисекундах() - МоментАктуальности)));

КонецФункции // ТребуетсяОбновление()

// Функция возвращает коллекцию параметров объекта
//   
// Параметры:
//   ИмяПоляКлюча 		- Строка	- имя поля, значение которого будет использовано
//									  в качестве ключа возвращаемого соответствия
//   
// Возвращаемое значение:
//	Соответствие - коллекция параметров объекта, для получения/изменения значений
//
Функция ПараметрыОбъекта(ИмяПоляКлюча = "ИмяПараметра") Экспорт

	Возврат ПараметрыЭлементов.Получить(ИмяПоляКлюча);

КонецФункции // ПараметрыОбъекта()

// Функция возвращает список объектов кластера
//   
// Параметры:
//   Отбор					 	- Структура	- Структура отбора объектов (<поле>:<значение>)
//   ОбновитьПринудительно 		- Булево	- Истина - принудительно обновить данные (вызов RAC)
//
// Возвращаемое значение:
//	Массив - список объектов кластера 1С
//
Функция Список(Отбор = Неопределено, ОбновитьПринудительно = Ложь) Экспорт

	ОбновитьДанные(ОбновитьПринудительно);

	Результат = Служебный.ПолучитьЭлементыИзМассиваСоответствий(Элементы, Отбор);

	Если Результат.Количество() = 0 Тогда
		Возврат Неопределено;
	Иначе
		Возврат Результат;
	КонецЕсли;

КонецФункции // Список()

// Функция возвращает список объектов кластера
//   
// Параметры:
//   ПоляИерархии			- Строка		- Поля для построения иерархии списка объектов, разделенные ","
//   ОбновитьПринудительно	- Булево		- Истина - принудительно обновить данные (вызов RAC)
//
// Возвращаемое значение:
//	Соответствие - список объектов кластера 1С
//		<имя поля объекта>	- Массив(Соответствие), Соответствие	- список объектов кластера или следующий уровень
//
Функция ИерархическийСписок(Знач ПоляИерархии, ОбновитьПринудительно = Ложь) Экспорт

	ОбновитьДанные(ОбновитьПринудительно);

	Результат = Служебный.ИерархическоеПредставлениеМассиваСоответствий(Элементы, ПоляИерархии);
	
	Возврат Результат;

КонецФункции // ИерархическийСписок()

// Функция возвращает количество обектов в списке профиля безопасности
//   
// Возвращаемое значение:
//	Число - количество объектов
//
Функция Количество() Экспорт

	ОбновитьДанные();

	Если Элементы = Неопределено Тогда
		Возврат 0;
	КонецЕсли;
	
	Возврат Элементы.Количество();

КонецФункции // Количество()

// Процедура устанавливает значение периода обновления
//   
// Параметры:
//   НовыйПериодОбновления 	- Число		- новый период обновления
//
Процедура УстановитьПериодОбновления(НовыйПериодОбновления) Экспорт

	ПериодОбновления = НовыйПериодОбновления;

КонецПроцедуры // УстановитьПериодОбновления()

// Процедура устанавливает новое значение момента актуальности данных
//   
Процедура УстановитьАктуальность() Экспорт

	МоментАктуальности = ТекущаяУниверсальнаяДатаВМиллисекундах();

КонецПроцедуры // УстановитьАктуальность()

// Процедура добавляет новый или изменяет существующий объект профиля безопасности
//   
// Параметры:
//   Имя			 	- Строка		- имя объекта профиля безопасности 1С
//   ПараметрыОбъекта 	- Структура		- параметры объекта профиля безопасности 1С
//
Процедура Изменить(Имя, ПараметрыОбъекта = Неопределено) Экспорт

	ПараметрыЗапуска = Новый Массив();
	ПараметрыЗапуска.Добавить(Кластер_Агент.СтрокаПодключения());

	ПараметрыЗапуска.Добавить("profile");
	ПараметрыЗапуска.Добавить("acl");
	ПараметрыЗапуска.Добавить(ТипЭлементов);
	ПараметрыЗапуска.Добавить("update");

	ПараметрыЗапуска.Добавить(СтрШаблон("--cluster=%1", Кластер_Владелец.Ид()));
	ПараметрыЗапуска.Добавить(Кластер_Владелец.СтрокаАвторизации());

	Если ВРег(ТипЭлементов) = ВРег(Перечисления.ВидыОбъектовПрофиляБезопасности.Каталог) Тогда
		ПараметрыЗапуска.Добавить(СтрШаблон("--alias=%1", Имя));
	Иначе
		ПараметрыЗапуска.Добавить(СтрШаблон("--name=%1", Имя));
	КонецЕсли;

	ВремПараметры = ПараметрыОбъекта();

	Для Каждого ТекЭлемент Из ВремПараметры Цикл
		ЗначениеПараметра = Служебный.ПолучитьЗначениеИзСтруктуры(ПараметрыОбъекта, ТекЭлемент.Ключ, 0);
		ПараметрыЗапуска.Добавить(СтрШаблон(ТекЭлемент.Значение.ПараметрКоманды + "=%1", ЗначениеПараметра));
	КонецЦикла;

	Кластер_Агент.ВыполнитьКоманду(ПараметрыЗапуска);
	
	Лог.Отладка(Кластер_Агент.ВыводКоманды(Ложь));

	ОбновитьДанные(Истина);

КонецПроцедуры // Изменить()

// Процедура удаляет объект профиля из профиля безопасности
//   
// Параметры:
//   Имя			- Строка	- Имя объекта профиля безопасности
//
Процедура Удалить(Имя) Экспорт
	
	ПараметрыЗапуска = Новый Массив();
	ПараметрыЗапуска.Добавить(Кластер_Агент.СтрокаПодключения());

	ПараметрыЗапуска.Добавить("profile");
	ПараметрыЗапуска.Добавить("acl");
	ПараметрыЗапуска.Добавить(ТипЭлементов);
	ПараметрыЗапуска.Добавить("remove");

	Если ВРег(ТипЭлементов) = ВРег(Перечисления.ВидыОбъектовПрофиляБезопасности.Каталог) Тогда
		ПараметрыЗапуска.Добавить(СтрШаблон("--alias=%1", Имя));
	Иначе
		ПараметрыЗапуска.Добавить(СтрШаблон("--name=%1", Имя));
	КонецЕсли;

	ПараметрыЗапуска.Добавить(СтрШаблон("--cluster=%1", Кластер_Владелец.Ид()));
	ПараметрыЗапуска.Добавить(Кластер_Владелец.СтрокаАвторизации());
	
	Кластер_Агент.ВыполнитьКоманду(ПараметрыЗапуска);
	
	Лог.Отладка(Кластер_Агент.ВыводКоманды(Ложь));

	ОбновитьДанные(Истина);

КонецПроцедуры // Удалить()

Лог = Логирование.ПолучитьЛог("ktb.lib.irac");
