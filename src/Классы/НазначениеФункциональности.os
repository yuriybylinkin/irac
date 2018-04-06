Перем Требование_Ид;		// rule
Перем Требование_Позиция;	// position
Перем Требование_Параметры;

Перем Кластер_Агент;
Перем Кластер_Владелец;
Перем Сервер_Владелец;

Перем ПараметрыОбъекта;

Перем ПериодОбновления;
Перем МоментАктуальности;

Перем Лог;

// Конструктор
//   
// Параметры:
//   АгентКластера		- АгентКластера	- ссылка на родительский объект, агент кластера
//   Кластер			- Кластер		- ссылка на родительский объект, кластер
//   Сервер				- Сервер		- ссылка на родительский объект, сервер
//   Ид					- Строка		- идентификатор требования назначения в кластере 1С
//
Процедура ПриСозданииОбъекта(АгентКластера, Кластер, Сервер, Ид)

	Если НЕ ЗначениеЗаполнено(Ид) Тогда
		Возврат;
	КонецЕсли;

	Кластер_Агент = АгентКластера;
	Кластер_Владелец = Кластер;
	Сервер_Владелец = Сервер;
	Требование_Ид = Ид;
	
	ПараметрыОбъекта = Новый ПараметрыОбъекта("server");

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

	Если НЕ Служебный.ТребуетсяОбновление(Требование_Параметры,
			МоментАктуальности, ПериодОбновления, ОбновитьПринудительно) Тогда
		Возврат;
	КонецЕсли;

	ПараметрыЗапуска = Новый Массив();
	ПараметрыЗапуска.Добавить(Кластер_Агент.СтрокаПодключения());

	ПараметрыЗапуска.Добавить("rule");
	ПараметрыЗапуска.Добавить("info");

	ПараметрыЗапуска.Добавить(СтрШаблон("--server=%1", Сервер_Владелец.Ид()));

	ПараметрыЗапуска.Добавить(СтрШаблон("--rule=%1", Ид()));

	ПараметрыЗапуска.Добавить(СтрШаблон("--cluster=%1", Кластер_Владелец.Ид()));
	ПараметрыЗапуска.Добавить(Кластер_Владелец.СтрокаАвторизации());

	Служебный.ВыполнитьКоманду(ПараметрыЗапуска);
	
	МассивРезультатов = Служебный.РазобратьВыводКоманды(Служебный.ВыводКоманды());

	ТекОписание = МассивРезультатов[0];

	ВремПараметры = ПараметрыОбъекта();

	Требование_Параметры = Новый Соответствие();

	Для Каждого ТекЭлемент Из ВремПараметры Цикл
		ЗначениеПараметра = Служебный.ПолучитьЗначениеИзСтруктуры(ТекОписание,
																  ТекЭлемент.Значение.ИмяПоляРАК,
																  ТекЭлемент.Значение.ЗначениеПоУмолчанию); 
		Требование_Параметры.Вставить(ТекЭлемент.Ключ, ЗначениеПараметра);
	КонецЦикла;

	МоментАктуальности = ТекущаяУниверсальнаяДатаВМиллисекундах();

КонецПроцедуры // ОбновитьДанные()

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

	Возврат ПараметрыОбъекта.Получить(ИмяПоляКлюча);

КонецФункции // ПараметрыОбъекта()

// Функция возвращает идентификатор требования назначения функциональности
//   
// Возвращаемое значение:
//	Строка - идентификатор требования назначения функциональности
//
Функция Ид() Экспорт

	Возврат Требование_Ид;

КонецФункции // Ид()

// Функция возвращает позицию требования назначения функциональности в списке (начиная с 0)
//   
// Возвращаемое значение:
//	Строка - позиция требования назначения функциональности в списке
//
Функция Позиция() Экспорт

	Если Служебный.ТребуетсяОбновление(Требование_Позиция, МоментАктуальности, ПериодОбновления) Тогда
		ОбновитьДанные(Истина);
	КонецЕсли;

	Возврат Требование_Позиция;
	
КонецФункции // Позиция()

// Функция возвращает значение параметра требования назначения функциональности
//   
// Параметры:
//   ИмяПоля			 	- Строка		- Имя параметра требования назначения функциональности
//   ОбновитьПринудительно 	- Булево		- Истина - обновить список (вызов RAC)
//
// Возвращаемое значение:
//	Произвольный - значение параметра требования назначения функциональности
//
Функция Получить(ИмяПоля, ОбновитьПринудительно = Ложь) Экспорт
	
	ОбновитьДанные(ОбновитьПринудительно);

	Если НЕ Найти(ВРЕг("Ид, server"), ВРег(ИмяПоля)) = 0 Тогда
		Возврат Требование_Ид;
	ИначеЕсли НЕ Найти(ВРЕг("Позиция, position"), ВРег(ИмяПоля)) = 0 Тогда
		Возврат Требование_Позиция;
	КонецЕсли;
	
	ЗначениеПоля = Требование_Параметры.Получить(ИмяПоля);

	Если ЗначениеПоля = Неопределено Тогда
		
		ОписаниеПараметра = ПараметрыОбъекта("ИмяПоляРАК").Получить(ИмяПоля);

		Если НЕ ОписаниеПараметра = Неопределено Тогда
			ЗначениеПоля = Требование_Параметры.Получить(ОписаниеПараметра["ИмяПараметра"]);
		КонецЕсли;
	КонецЕсли;

	Возврат ЗначениеПоля;
		
КонецФункции // Получить()
	
// Процедура изменяет параметры требования назначения функциональности
//   
// Параметры:
//   ПараметрыТребования	 	- Структура		- новые параметры требования назначения функциональности
//
Процедура Изменить(Знач ПараметрыТребования = Неопределено) Экспорт

	Если НЕ ТипЗнч(ПараметрыТребования) = Тип("Структура") Тогда
		ПараметрыТребования = Новый Структура();
	КонецЕсли;

	ПараметрыЗапуска = Новый Массив();
	ПараметрыЗапуска.Добавить(Кластер_Агент.СтрокаПодключения());

	ПараметрыЗапуска.Добавить("rule");
	ПараметрыЗапуска.Добавить("update");

	ПараметрыЗапуска.Добавить(СтрШаблон("--rule=%1", Ид()));

	ПараметрыЗапуска.Добавить(СтрШаблон("--cluster=%1", Кластер_Владелец.Ид()));
	ПараметрыЗапуска.Добавить(Кластер_Владелец.СтрокаАвторизации());
		
	ПараметрыЗапуска.Добавить(СтрШаблон("--position=%1", Требование_Позиция));

	ВремПараметры = ПараметрыОбъекта();

	Для Каждого ТекЭлемент Из ВремПараметры Цикл
		Если НЕ ПараметрыТребования.Свойство(ТекЭлемент.Ключ) Тогда
			Продолжить;
		КонецЕсли;
		ПараметрыЗапуска.Добавить(СтрШаблон(ТекЭлемент.ПараметрКоманды + "=%1", ПараметрыТребования[ТекЭлемент.Ключ]));
	КонецЦикла;

	Служебный.ВыполнитьКоманду(ПараметрыЗапуска);
	
	Лог.Информация(Служебный.ВыводКоманды());

	ОбновитьДанные();

КонецПроцедуры // Изменить()

Лог = Логирование.ПолучитьЛог("ktb.lib.irac");
