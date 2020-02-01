﻿
// Copyright 2020 Tsukanov Alexander. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

#Область РеализацияКонвейера

Процедура Вызвать(ОбработчикЗадания, Переменные) Экспорт
	
	КонтекстЗадания = Новый Структура;
	КонтекстЗадания.Вставить("Переменные", Переменные);
	КонтекстЗадания.Вставить("СледующийОбработчикЗадания", Неопределено); // заполняется при вызове _ВыполнитьОбработчикЗадания()
	
	ВыполнитьОбработкуОповещения(ОбработчикЗадания, КонтекстЗадания);
	
КонецПроцедуры

Процедура ПодготовитьСценарий(Сценарий, ОбработчикОшибок, ОбработчикЗаданияДляВозврата) Экспорт
	
	ДиспетчерЗаданий = Сценарий.Форма;
	Если ДиспетчерЗаданий = Неопределено Тогда
		ДиспетчерЗаданий = ЭтотОбъект;
	КонецЕсли; 
	
	Задания = Сценарий.Задания;
	
	ИндексЗадания = Задания.Количество();
	
	ПараметрыЗадания = Новый Структура;
	ПараметрыЗадания.Вставить("СледующийОбработчикЗадания", ОбработчикЗаданияДляВозврата);
	
	_ВыполнитьОператорВозврат = Новый ОписаниеОповещения(
		"_ВыполнитьОператорВозврат",
		ЭтотОбъект,
		ПараметрыЗадания
	);
	
	ОбработчикЗадания = ДиспетчерЗаданий.ОбработчикЗадания(_ВыполнитьОператорВозврат, Неопределено, ОбработчикОшибок);
	
	СтекОбработчиковКонецЕсли = Новый Массив;
	СтекОбработчиковЕслиЛожь = Новый Массив;
	СтекОбработчиковКонецПопытки = Новый Массив;
	СтекТочекВходаПослеИсключения = Новый Массив;
	
	// для одноразовой подмены обработчика следующего по порядку заданий
	// нужно для установки переходов на КонецЕсли после веток например
	СледующийОбработчикЗадания = Неопределено;
	
	Пока ИндексЗадания > 0 Цикл
		
		ИндексЗадания = ИндексЗадания - 1;
		Задание = Задания[ИндексЗадания];
		ПараметрыЗадания = Задание.ДополнительныеПараметры;
		
		Если СтекТочекВходаПослеИсключения.Количество() > 0 Тогда
			ПараметрыЗадания.ОбработчикЗаданияОператорИсключение = ВзятьПоследнееЗначение(СтекТочекВходаПослеИсключения); 
		КонецЕсли; 
		
		Если СледующийОбработчикЗадания = Неопределено Тогда
			ОбработчикЗадания = ДиспетчерЗаданий.ОбработчикЗадания(Задание, ОбработчикЗадания, ОбработчикОшибок);
		Иначе
			ОбработчикЗадания = ДиспетчерЗаданий.ОбработчикЗадания(Задание, СледующийОбработчикЗадания, ОбработчикОшибок);
			СледующийОбработчикЗадания = Неопределено;
		КонецЕсли; 
		
		Если Задание.Модуль = ЭтотОбъект Тогда
			
			// TODO: проверять синтаксис
			
			ИмяПроцедурыЗадания = Задание.ИмяПроцедуры;
			
			Если ИмяПроцедурыЗадания = "_ВыполнитьОператорКонецЕсли" Тогда
							
				СтекОбработчиковКонецЕсли.Добавить(ОбработчикЗадания);
				СтекОбработчиковЕслиЛожь.Добавить(ОбработчикЗадания);
								
			ИначеЕсли ИмяПроцедурыЗадания = "_ВыполнитьОператорИначе" Тогда
				
				ОбработчикЗаданияОператорКонецЕсли = СнятьПоследнееЗначение(СтекОбработчиковЕслиЛожь);
				
				Инвариант(ОбработчикЗаданияОператорКонецЕсли.ДополнительныеПараметры.Задание.ИмяПроцедуры = "_ВыполнитьОператорКонецЕсли");
				
				СтекОбработчиковЕслиЛожь.Добавить(ОбработчикЗадания);
				
				// Заданию перед оператором "Иначе" нужно установить следующий обработчик = "КонецЕсли"
				СледующийОбработчикЗадания = ВзятьПоследнееЗначение(СтекОбработчиковКонецЕсли);;
				
			ИначеЕсли ИмяПроцедурыЗадания = "_ВыполнитьОператорИначеЕсли" Тогда
								
				ПараметрыЗадания.ОбработчикЗаданияЕслиЛожь = СнятьПоследнееЗначение(СтекОбработчиковЕслиЛожь);	
				
				ИмяПроцедурыЗаданияЕслиЛожь = ПараметрыЗадания.ОбработчикЗаданияЕслиЛожь.ДополнительныеПараметры.Задание.ИмяПроцедуры;
				
				Инвариант(Ложь
					Или ИмяПроцедурыЗаданияЕслиЛожь = "_ВыполнитьОператорКонецЕсли"
					Или ИмяПроцедурыЗаданияЕслиЛожь = "_ВыполнитьОператорИначе"
					Или ИмяПроцедурыЗаданияЕслиЛожь = "_ВыполнитьОператорИначеЕсли"
				);
				
				СтекОбработчиковЕслиЛожь.Добавить(ОбработчикЗадания);
				
				// Заданию перед оператором "ИначеЕсли" нужно установить следующий обработчик = "КонецЕсли" 		
				СледующийОбработчикЗадания = ВзятьПоследнееЗначение(СтекОбработчиковКонецЕсли);
				
			ИначеЕсли ИмяПроцедурыЗадания = "_ВыполнитьОператорЕсли" Тогда
								
				ПараметрыЗадания.ОбработчикЗаданияЕслиЛожь = СнятьПоследнееЗначение(СтекОбработчиковЕслиЛожь);
				СнятьПоследнееЗначение(СтекОбработчиковКонецЕсли);
				
			ИначеЕсли ИмяПроцедурыЗадания = "_ВыполнитьОператорКонецПопытки" Тогда
				
				СтекОбработчиковКонецПопытки.Добавить(ОбработчикЗадания);
				
			ИначеЕсли ИмяПроцедурыЗадания = "_ВыполнитьОператорИсключение" Тогда
				
				ОбработчикЗаданияОператорКонецПопытки = СнятьПоследнееЗначение(СтекОбработчиковКонецПопытки);
				
				СтекТочекВходаПослеИсключения.Добавить(ОбработчикЗадания.ДополнительныеПараметры.СледующийОбработчикЗадания);
				ОбработчикЗадания.ДополнительныеПараметры.СледующийОбработчикЗадания = ОбработчикЗаданияОператорКонецПопытки;
								
			ИначеЕсли ИмяПроцедурыЗадания = "_ВыполнитьОператорПопытка" Тогда
				
				СнятьПоследнееЗначение(СтекТочекВходаПослеИсключения);
				
			КонецЕсли; 
			
		КонецЕсли; 
				
	КонецЦикла; 
	
	Инвариант(СтекОбработчиковКонецЕсли.Количество() = 0);
	Инвариант(СтекОбработчиковЕслиЛожь.Количество() = 0);
	Инвариант(СтекОбработчиковКонецПопытки.Количество() = 0);
	Инвариант(СтекТочекВходаПослеИсключения.Количество() = 0);
	Инвариант(СледующийОбработчикЗадания = Неопределено);
	
	Сценарий.ОбработчикПервогоЗадания = ОбработчикЗадания;
	
	ДиспетчерЗаданий.ПодготовитьОтладочныйКонтекстСценария(Сценарий);
	
КонецПроцедуры 

Процедура ПодготовитьОтладочныйКонтекстСценария(Сценарий) Экспорт
	
	// см. ОбщаяФорма.КонвейерЗаданий.ПодготовитьОтладочныйКонтекстСценария(Сценарий)
	
КонецПроцедуры 

Процедура _ВыполнитьОбработчикЗадания(КонтекстЗадания, ПараметрыОбработчикаЗадания) Экспорт
	
	Попытка
						
		КонтекстЗадания.СледующийОбработчикЗадания = ПараметрыОбработчикаЗадания.СледующийОбработчикЗадания;
		
		ФиксированныйКонтекстЗадания = Новый ФиксированнаяСтруктура(КонтекстЗадания);
		ВыполнитьОбработкуОповещения(ПараметрыОбработчикаЗадания.Задание, ФиксированныйКонтекстЗадания);
		
	Исключение
		
		СтандартнаяОбработка = Истина;
		
		Если ПараметрыОбработчикаЗадания.ОбработчикОшибок <> Неопределено Тогда 
			КонтекстОшибки = КонтекстОшибки(ИнформацияОбОшибке(), КонтекстЗадания.Переменные);
			ВыполнитьОбработкуОповещения(ПараметрыОбработчикаЗадания.ОбработчикОшибок, КонтекстОшибки);	
			СтандартнаяОбработка = КонтекстОшибки.СтандартнаяОбработка; 				
		КонецЕсли; 
		
		Если СтандартнаяОбработка = Истина Тогда // безопасная проверка
			ПараметрыЗадания = ПараметрыОбработчикаЗадания.Задание.ДополнительныеПараметры;
			Если ПараметрыЗадания.ОбработчикЗаданияОператорИсключение = Неопределено Тогда
				ВызватьИсключение;
			Иначе
				Вызвать(ПараметрыЗадания.ОбработчикЗаданияОператорИсключение, КонтекстЗадания.Переменные);
			КонецЕсли; 
		КонецЕсли;
		
	КонецПопытки;
	
КонецПроцедуры

Процедура _ОбработатьОшибку(ИнформацияОбОшибке, СтандартнаяОбработка, ПараметрыДекоратора) Экспорт
	
	Если ПараметрыДекоратора.ОбработчикОшибок <> Неопределено Тогда
		
		КонтекстОшибки = КонтекстОшибки(ИнформацияОбОшибке, ПараметрыДекоратора.Переменные);
		ВыполнитьОбработкуОповещения(ПараметрыДекоратора.ОбработчикОшибок, КонтекстОшибки);	
		СтандартнаяОбработка = КонтекстОшибки.СтандартнаяОбработка;
	
	КонецЕсли; 
	
	Если СтандартнаяОбработка = Истина Тогда // безопасная проверка
		Если ПараметрыДекоратора.ОбработчикЗаданияОператорИсключение <> Неопределено Тогда
			Вызвать(ПараметрыДекоратора.ОбработчикЗаданияОператорИсключение, ПараметрыДекоратора.Переменные);
			СтандартнаяОбработка = Ложь;
		КонецЕсли; 
	КонецЕсли;
	
КонецПроцедуры

Функция ОбработчикЗадания(Задание, СледующийОбработчикЗадания, ОбработчикОшибок) Экспорт
	
	ПараметрыОбработчикаЗадания = Новый Структура;
	ПараметрыОбработчикаЗадания.Вставить("Задание", Задание);
	ПараметрыОбработчикаЗадания.Вставить("СледующийОбработчикЗадания", СледующийОбработчикЗадания);
	ПараметрыОбработчикаЗадания.Вставить("ОбработчикОшибок", ОбработчикОшибок);
	
	_ВыполнитьОбработчикЗадания = Новый ОписаниеОповещения(
		"_ВыполнитьОбработчикЗадания",
		ЭтотОбъект,
		ПараметрыОбработчикаЗадания
	);
	
	Возврат _ВыполнитьОбработчикЗадания;
	
КонецФункции

Функция КонтекстОшибки(ИнформацияОбОшибке, Переменные)
	
	КонтекстОшибки = Новый Структура;
	КонтекстОшибки.Вставить("ИнформацияОбОшибке", ИнформацияОбОшибке);
	КонтекстОшибки.Вставить("Переменные", Переменные);
	КонтекстОшибки.Вставить("СтандартнаяОбработка", Истина);
	
	Возврат КонтекстОшибки;
	
КонецФункции

#КонецОбласти // РеализацияКонвейера

#Область РеализацияЗаданий

Процедура _ВыполнитьПроизвольноеЗадание(КонтекстЗадания, ПараметрыЗадания) Экспорт
	
	ПодготовитьПараметрыДекоратора(КонтекстЗадания, ПараметрыЗадания);
	
	ВыполнитьОбработкуОповещения(ПараметрыЗадания.ДекорированныйОбработчик, КонтекстЗадания.Переменные);
		
КонецПроцедуры 

Процедура _ВыполнитьЗаданиеДиалогВыбораФайла(КонтекстЗадания, ПараметрыЗадания) Экспорт
	
	ПодготовитьПараметрыДекоратора(КонтекстЗадания, ПараметрыЗадания);
	
	_ПоказатьДиалогВыбораФайла = Новый ОписаниеОповещения(
		"_ПоказатьДиалогВыбораФайла",
		ЭтотОбъект,
		ПараметрыЗадания
	);
	
	НачатьПослеПодключенияРасширенияРаботыСФайлами(_ПоказатьДиалогВыбораФайла);
	
КонецПроцедуры

Процедура _ВыполнитьЗаданиеСозданиеКаталога(КонтекстЗадания, ПараметрыЗадания) Экспорт
	
	ПодготовитьПараметрыДекоратора(КонтекстЗадания, ПараметрыЗадания);
		
	_НачатьСозданиеКаталога = Новый ОписаниеОповещения(
		"_НачатьСозданиеКаталога",
		ЭтотОбъект,
		ПараметрыЗадания
	);
	
	НачатьПослеПодключенияРасширенияРаботыСФайлами(_НачатьСозданиеКаталога);
	
КонецПроцедуры 

Процедура _ВыполнитьЗаданиеУдалениеФайлов(КонтекстЗадания, ПараметрыЗадания) Экспорт
	
	ПодготовитьПараметрыДекоратора(КонтекстЗадания, ПараметрыЗадания);
		
	_НачатьУдалениеФайлов = Новый ОписаниеОповещения(
		"_НачатьУдалениеФайлов",
		ЭтотОбъект,
		ПараметрыЗадания
	);
	
	НачатьПослеПодключенияРасширенияРаботыСФайлами(_НачатьУдалениеФайлов);
	
КонецПроцедуры

Процедура _ВыполнитьЗаданиеДиалогВопроса(КонтекстЗадания, ПараметрыЗадания) Экспорт
	
	ПодготовитьПараметрыДекоратора(КонтекстЗадания, ПараметрыЗадания);
		
	_ПоказатьВопрос = Новый ОписаниеОповещения(
		"_ПоказатьВопрос",
		ЭтотОбъект,
		ПараметрыЗадания
	);
	
	ВыполнитьОбработкуОповещения(_ПоказатьВопрос, Неопределено);
	
КонецПроцедуры

#КонецОбласти // РеализацияЗаданий

#Область РеализацияОператоров

Процедура _ВыполнитьОператорЕсли(КонтекстЗадания, ПараметрыЗадания) Экспорт
		
	РезультатУсловия = ВыполнитьОбработкуОповещения(ПараметрыЗадания.Обработчик, КонтекстЗадания.Переменные);
	
	Если РезультатУсловия <> Истина Тогда // безопасная проверка
		
		Вызвать(
			ПараметрыЗадания.ОбработчикЗаданияЕслиЛожь,
			КонтекстЗадания.Переменные
		);
		
	Иначе	
		
		Вызвать(
			КонтекстЗадания.СледующийОбработчикЗадания,
			КонтекстЗадания.Переменные
		); 
		
	КонецЕсли;
		
КонецПроцедуры

Процедура _ВыполнитьОператорИначеЕсли(КонтекстЗадания, ПараметрыЗадания) Экспорт
		
	РезультатУсловия = ВыполнитьОбработкуОповещения(ПараметрыЗадания.Обработчик, КонтекстЗадания.Переменные);
	
	Если РезультатУсловия <> Истина Тогда // безопасная проверка
		
		Вызвать(
			ПараметрыЗадания.ОбработчикЗаданияЕслиЛожь,
			КонтекстЗадания.Переменные
		);
		
	Иначе	
		
		Вызвать(
			КонтекстЗадания.СледующийОбработчикЗадания,
			КонтекстЗадания.Переменные
		); 
		
	КонецЕсли;
		
КонецПроцедуры

Процедура _ВыполнитьОператорИначе(КонтекстЗадания, ПараметрыЗадания) Экспорт
	
	Инвариант(КонтекстЗадания.СледующийОбработчикЗадания <> Неопределено); 
	
	Вызвать(
		КонтекстЗадания.СледующийОбработчикЗадания,
		КонтекстЗадания.Переменные
	);	
	
КонецПроцедуры

Процедура _ВыполнитьОператорКонецЕсли(КонтекстЗадания, ПараметрыЗадания) Экспорт
	
	Инвариант(КонтекстЗадания.СледующийОбработчикЗадания <> Неопределено); 
	
	Вызвать(
		КонтекстЗадания.СледующийОбработчикЗадания,
		КонтекстЗадания.Переменные
	);	
	
КонецПроцедуры

Процедура _ВыполнитьОператорПопытка(КонтекстЗадания, ПараметрыЗадания) Экспорт
	
	Инвариант(КонтекстЗадания.СледующийОбработчикЗадания <> Неопределено); 
	
	Вызвать(
		КонтекстЗадания.СледующийОбработчикЗадания,
		КонтекстЗадания.Переменные
	);	
	
КонецПроцедуры

Процедура _ВыполнитьОператорИсключение(КонтекстЗадания, ПараметрыЗадания) Экспорт
	
	Инвариант(КонтекстЗадания.СледующийОбработчикЗадания <> Неопределено); 
	
	Вызвать(
		КонтекстЗадания.СледующийОбработчикЗадания,
		КонтекстЗадания.Переменные
	);	
	
КонецПроцедуры

Процедура _ВыполнитьОператорКонецПопытки(КонтекстЗадания, ПараметрыЗадания) Экспорт
	
	Инвариант(КонтекстЗадания.СледующийОбработчикЗадания <> Неопределено); 
	
	Вызвать(
		КонтекстЗадания.СледующийОбработчикЗадания,
		КонтекстЗадания.Переменные
	);	
	
КонецПроцедуры

Процедура _ВыполнитьОператорВозврат(КонтекстЗадания, ПараметрыЗадания) Экспорт
	
	Вызвать(
		ПараметрыЗадания.СледующийОбработчикЗадания,
		КонтекстЗадания.Переменные
	);
	
КонецПроцедуры

#КонецОбласти // РеализацияОператоров

#Область Заглушка

// Заглушка, которая используется в стандартных этапах в качестве обработчика если последний не указан.

Функция ОписаниеОбработчикаЗаглушки() Экспорт
	
	Возврат Новый ОписаниеОповещения("_ОбработчикЗаглушка", ЭтотОбъект);
	
КонецФункции

Процедура _ОбработчикЗаглушка(Результат, ДополнительныеПараметры) Экспорт
	
КонецПроцедуры

#КонецОбласти // Заглушка

#Область Обертки

// Простые обертки методов платформы, чтобы иметь возможность вызывать их через ВыполнитьОбработкуОповещения()

Процедура _ПоказатьДиалогВыбораФайла(Ничего, ПараметрыМетода) Экспорт
		
	ДиалогВыбораФайла = ПараметрыМетода.ДиалогВыбораФайла;
	ДиалогВыбораФайла.Показать(ПараметрыМетода.ДекорированныйОбработчик);	
	
КонецПроцедуры

Процедура _НачатьУдалениеФайлов(Ничего, ПараметрыМетода) Экспорт
		
	НачатьУдалениеФайлов(
		ПараметрыМетода.ДекорированныйОбработчик,
		ИзвлечьЗначение(ПараметрыМетода.Путь),
		ИзвлечьЗначение(ПараметрыМетода.Маска)
	);	
	
КонецПроцедуры

Процедура _НачатьСозданиеКаталога(Ничего, ПараметрыМетода) Экспорт
		
	НачатьСозданиеКаталога(
		ПараметрыМетода.ДекорированныйОбработчик,
		ИзвлечьЗначение(ПараметрыМетода.ИмяКаталога)
	);	
	
КонецПроцедуры

Процедура _ПоказатьВопрос(Ничего, ПараметрыМетода) Экспорт
	
	ПоказатьВопрос(
		ПараметрыМетода.ДекорированныйОбработчик,
		ИзвлечьЗначение(ПараметрыМетода.ТекстВопроса),
		ИзвлечьЗначение(ПараметрыМетода.Кнопки), 
		ИзвлечьЗначение(ПараметрыМетода.Таймаут), 
		ИзвлечьЗначение(ПараметрыМетода.КнопкаПоУмолчанию), 
		ИзвлечьЗначение(ПараметрыМетода.Заголовок), 
		ИзвлечьЗначение(ПараметрыМетода.КнопкаТаймаута)
	);	
	
КонецПроцедуры

#КонецОбласти // Обертки

#Область ДекораторыОбработчиков

// Декораторы, которые расширяют логику пользовательских обработчиков.
// Например, добавляют в конце передачу управления на следующий этап конвейера.

Функция ДекорироватьОбработчик(Знач Обработчик, ИмяДекоратора = "_ВыполнитьОбработчик2") Экспорт
	
	Если Обработчик = Неопределено Тогда
		Обработчик = ОписаниеОбработчикаЗаглушки();	
	КонецЕсли;
	
	ПараметрыДекоратора = Новый Структура;
	ПараметрыДекоратора.Вставить("Обработчик", Обработчик);
	ПараметрыДекоратора.Вставить("СледующийОбработчикЗадания", Неопределено);
	ПараметрыДекоратора.Вставить("Переменные", Неопределено);
	ПараметрыДекоратора.Вставить("ОбработчикОшибок", Неопределено);
	ПараметрыДекоратора.Вставить("ОбработчикЗаданияОператорИсключение", Неопределено);
	
	ДекорированныйОбработчик = Новый ОписаниеОповещения(
		ИмяДекоратора,
		ЭтотОбъект,
		ПараметрыДекоратора,
		"_ОбработатьОшибку",
		ЭтотОбъект
	);
	
	Возврат ДекорированныйОбработчик;
	
КонецФункции  

Процедура _ВыполнитьОбработчик1(ПараметрыДекоратора) Экспорт
	
	ВыполнитьОбработкуОповещения(ПараметрыДекоратора.Обработчик);
	
	Вызвать(
		ПараметрыДекоратора.СледующийОбработчикЗадания,
		ПараметрыДекоратора.Переменные
	);
	
КонецПроцедуры

Процедура _ВыполнитьОбработчик2(Результат, ПараметрыДекоратора) Экспорт
	
	ВыполнитьОбработкуОповещения(ПараметрыДекоратора.Обработчик, Результат);
	
	Вызвать(
		ПараметрыДекоратора.СледующийОбработчикЗадания,
		ПараметрыДекоратора.Переменные
	);
	
КонецПроцедуры

#КонецОбласти // ДекораторыОбработчиков

#Область ПодключениеРасширенияРаботыСФайлами

Процедура НачатьПослеПодключенияРасширенияРаботыСФайлами(ОписаниеОповещения) Экспорт
	
	ДополнительныеПараметры = Новый Структура;
	ДополнительныеПараметры.Insert("ОписаниеОповещения", ОписаниеОповещения);
	
	ОбработатьПодключениеРасширенияРаботыСФайлами = Новый ОписаниеОповещения(
		"ОбработатьПодключениеРасширенияРаботыСФайлами",
		ЭтотОбъект,
		ДополнительныеПараметры	
	);
	
	НачатьПодключениеРасширенияРаботыСФайлами(ОбработатьПодключениеРасширенияРаботыСФайлами)
	
КонецПроцедуры

Процедура ОбработатьПодключениеРасширенияРаботыСФайлами(Результат, ДополнительныеПараметры) Экспорт
	
	Если Результат = Неопределено Тогда
		Возврат;
	КонецЕсли;
	
	Подключено = Результат;
	
	Если Подключено Тогда
		
		ВыполнитьОбработкуОповещения(ДополнительныеПараметры.ОписаниеОповещения);
		
	Иначе
		
		ТекстВопроса = NStr(
			"ru = 'Требуется установка расширения для работы с файлами. Продолжить?' ;
			|en = 'File system extension needs to be installed. Continue?'"
		);
		
		ОбработатьОтветНаВопросОбУстановкеРасширенияРаботыСФайлами = Новый ОписаниеОповещения(
			"ОбработатьОтветНаВопросОбУстановкеРасширенияРаботыСФайлами",
			ЭтотОбъект,
			ДополнительныеПараметры
		);
		
		ПоказатьВопрос(ОбработатьОтветНаВопросОбУстановкеРасширенияРаботыСФайлами, ТекстВопроса, РежимДиалогаВопрос.ДаНет);
		
	КонецЕсли;

КонецПроцедуры 

Процедура ОбработатьОтветНаВопросОбУстановкеРасширенияРаботыСФайлами(Результат, ДополнительныеПараметры) Экспорт
	
	Если Результат = Неопределено Тогда
		Возврат;
	КонецЕсли;
	
	Ответ = Результат;
	
	Если Ответ = КодВозвратаДиалога.Да Тогда
	
		ОбработатьУстановкуРасширенияРаботыСФайлами = Новый ОписаниеОповещения(
			"ОбработатьУстановкуРасширенияРаботыСФайлами",
			ЭтотОбъект,
			ДополнительныеПараметры
		);
		
		НачатьУстановкуРасширенияРаботыСФайлами(ОбработатьУстановкуРасширенияРаботыСФайлами);
	
	КонецЕсли; 
	
КонецПроцедуры

Процедура ОбработатьУстановкуРасширенияРаботыСФайлами(ДополнительныеПараметры) Экспорт
		
 	ОбработатьПодключениеРасширенияРаботыСФайлами = Новый ОписаниеОповещения(
		"ОбработатьПодключениеРасширенияРаботыСФайлами", 
		ЭтотОбъект,
		ДополнительныеПараметры
	);
	
	НачатьПодключениеРасширенияРаботыСФайлами(ОбработатьПодключениеРасширенияРаботыСФайлами);
	
КонецПроцедуры

#КонецОбласти // ПодключениеРасширенияРаботыСФайлами

#Область СлужебныеМетоды

Процедура ПодготовитьПараметрыДекоратора(КонтекстЗадания, ПараметрыЗадания)
	
	ПараметрыДекоратора = ПараметрыЗадания.ДекорированныйОбработчик.ДополнительныеПараметры;
	
	Инвариант(ПараметрыДекоратора <> Неопределено);	
	
	// Для передачи управления на следующее задание в декораторах нужна дополнительная информация.
	// В заданиях такой проблемы нет, так как им передается контекст, содержащий эту информацию.
	// Например в _ВыполнитьЗаданиеДиалогВыбораФайла() будет подготовлена информация для передачи в _ВыполнитьОбработчик2(). 
	ПараметрыДекоратора.СледующийОбработчикЗадания = КонтекстЗадания.СледующийОбработчикЗадания;
	ПараметрыДекоратора.Переменные = КонтекстЗадания.Переменные;
	
	// При обработке системной ошибки нужно иметь возможность вызвать указанный для задания произвольный обработчик ошибок.
	// см. ОбработатьОшибку()
	ПараметрыДекоратора.ОбработчикОшибок = ПараметрыЗадания.ОбработчикОшибок;
	ПараметрыДекоратора.ОбработчикЗаданияОператорИсключение = ПараметрыЗадания.ОбработчикЗаданияОператорИсключение;
	
КонецПроцедуры

Процедура Инвариант(Условие, ТекстИсключения = Неопределено)
	
	Если Не Условие Тогда
		Если ТекстИсключения = Неопределено Тогда
			ТекстИсключения = НСтр(
				"ru = 'нарушение протокола';
				|en = 'violation of protocol'"
			);
		КонецЕсли; 
		ВызватьИсключение ТекстИсключения;
	КонецЕсли;
	
КонецПроцедуры 	

Функция СнятьПоследнееЗначение(Стек)
	
	ИндексВершиныСтека = Стек.ВГраница();
	Значение = Стек[ИндексВершиныСтека];
	Стек.Удалить(ИндексВершиныСтека);
	
	Возврат Значение;
	
КонецФункции 

Функция ВзятьПоследнееЗначение(Стек)
		
	Возврат Стек[Стек.ВГраница()];
	
КонецФункции

Функция ИзвлечьЗначение(Значение) Экспорт
	
	Если ТипЗнч(Значение) = Тип("ФиксированнаяСтруктура")
		И Значение.Свойство("__Коллекция")
		И Значение.Свойство("__Ключ") Тогда
		Возврат Значение.__Коллекция[Значение.__Ключ]
	Иначе
		Возврат Значение;
	КонецЕсли; 
	
КонецФункции 

Функция Ссылка(Коллекция, Ключ) Экспорт
	
	Возврат Новый ФиксированнаяСтруктура("__Коллекция, __Ключ", Коллекция, Ключ);
	
КонецФункции 

#КонецОбласти // СлужебныеМетоды