CREATE TABLE [MI].[LoyaltyBalanceDates] (
    [DateTypePeriodID] TINYINT NOT NULL,
    [LoyaltyDate]      DATE    NOT NULL,
    CONSTRAINT [PK_MI_LoyaltyBalanceDates] PRIMARY KEY CLUSTERED ([DateTypePeriodID] ASC)
);

