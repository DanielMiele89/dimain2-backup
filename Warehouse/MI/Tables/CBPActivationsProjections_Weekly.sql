CREATE TABLE [MI].[CBPActivationsProjections_Weekly] (
    [Version]                      INT    NOT NULL,
    [WeekStartDate]                DATE   NOT NULL,
    [ActivationForecast]           BIGINT NOT NULL,
    [DebitCardOnly]                BIGINT NULL,
    [DebitAndCredit]               BIGINT NULL,
    [CreditCardOnly]               BIGINT NULL,
    [ActivationForecast_emailable] BIGINT NULL,
    [DebitCardOnly_emailable]      BIGINT NULL,
    [DebitAndCredit_emailable]     BIGINT NULL,
    [CreditCardOnly_emailable]     BIGINT NULL,
    [ActivationForecast_eligible]  BIGINT NULL,
    [DebitCardOnly_eligible]       BIGINT NULL,
    [DebitAndCredit_eligible]      BIGINT NULL,
    [CreditCardOnly_eligible]      BIGINT NULL,
    [ActivationForecast_engaged]   BIGINT NULL,
    [DebitCardOnly_engaged]        BIGINT NULL,
    [DebitAndCredit_engaged]       BIGINT NULL,
    [CreditCardOnly_engaged]       BIGINT NULL
);

