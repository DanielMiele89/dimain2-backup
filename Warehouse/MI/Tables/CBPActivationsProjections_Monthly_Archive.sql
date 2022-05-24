CREATE TABLE [MI].[CBPActivationsProjections_Monthly_Archive] (
    [Version]            INT    NOT NULL,
    [CalendarYear]       INT    NOT NULL,
    [CalendarMonth]      INT    NOT NULL,
    [ActivationForecast] BIGINT NOT NULL,
    [DebitCardOnly]      BIGINT NULL,
    [DebitandCredit]     BIGINT NULL,
    [CreditCardOnly]     BIGINT NULL,
    CONSTRAINT [PK_A] PRIMARY KEY CLUSTERED ([CalendarYear] ASC, [CalendarMonth] ASC, [Version] ASC)
);

