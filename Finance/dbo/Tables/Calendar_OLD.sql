﻿CREATE TABLE [dbo].[Calendar_OLD] (
    [CalendarDate]               DATE         NOT NULL,
    [CalendarDay]                INT          NULL,
    [CalendarDaySuffix]          CHAR (2)     NULL,
    [CalendarDayName]            VARCHAR (30) NULL,
    [CalendarDayOfWeek]          INT          NULL,
    [CalendarDayOfYear]          INT          NULL,
    [isCurrentDay]               VARCHAR (1)  NOT NULL,
    [isPreviousDay]              VARCHAR (1)  NOT NULL,
    [isPenultimateDay]           VARCHAR (1)  NOT NULL,
    [IsWeekend]                  INT          NOT NULL,
    [CalendarWeekOfYear]         INT          NULL,
    [ISOWeekOfYear]              INT          NULL,
    [CalendarWeekStartDate]      DATE         NULL,
    [CalendarWeekEndDate]        DATE         NULL,
    [CalendarWeekOfMonth]        TINYINT      NULL,
    [isCurrentWeek]              VARCHAR (1)  NOT NULL,
    [isPreviousWeek]             VARCHAR (1)  NOT NULL,
    [isPenultimateWeek]          VARCHAR (1)  NOT NULL,
    [CalendarMonth]              INT          NULL,
    [CalendarMonthName]          VARCHAR (30) NULL,
    [CalendarMonthStartDate]     DATE         NULL,
    [CalendarMonthEndDate]       DATE         NULL,
    [NextCalendarMonthStartDate] DATE         NULL,
    [NextCalendarMonthEndDate]   DATE         NULL,
    [isCurrentMonth]             VARCHAR (1)  NOT NULL,
    [isPreviousMonth]            VARCHAR (1)  NOT NULL,
    [isPenultimateMonth]         VARCHAR (1)  NOT NULL,
    [CalendarQuarter]            INT          NULL,
    [CalendarQuarterStartDate]   DATE         NULL,
    [CalendarQuarterEndDate]     DATE         NULL,
    [CalendarYear]               INT          NULL,
    [ISOYear]                    INT          NULL,
    [CalendarYearStartDate]      DATE         NULL,
    [CalendarYearEndDate]        DATE         NULL,
    [IsLeapYear]                 BIT          NULL,
    [isCurrentYear]              VARCHAR (1)  NOT NULL,
    [isPreviousYear]             VARCHAR (1)  NOT NULL,
    [isPenultimateYear]          VARCHAR (1)  NOT NULL,
    [Has53Weeks]                 INT          NOT NULL,
    [Has53ISOWeeks]              INT          NOT NULL,
    [FinancialWeek]              INT          NULL,
    [FinancialQtr]               INT          NULL,
    [FinancialYear]              INT          NULL,
    CONSTRAINT [pk_Calendar_OLD] PRIMARY KEY CLUSTERED ([CalendarDate] ASC)
);
