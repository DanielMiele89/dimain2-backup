CREATE TABLE [MI].[CBPActivationsProjections_Monthly] (
    [Version]            INT    NOT NULL,
    [CalendarYear]       INT    NOT NULL,
    [CalendarMonth]      INT    NOT NULL,
    [ActivationForecast] BIGINT NOT NULL,
    [DebitCardOnly]      BIGINT NULL,
    [DebitAndCredit]     BIGINT NULL,
    [CreditCardOnly]     BIGINT NULL,
    CONSTRAINT [PK] PRIMARY KEY CLUSTERED ([CalendarYear] ASC, [CalendarMonth] ASC),
    CHECK ([CalendarMonth]<=(12)),
    CHECK ([CalendarMonth]>=(1))
);

