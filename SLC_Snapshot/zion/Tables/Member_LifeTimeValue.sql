CREATE TABLE [zion].[Member_LifeTimeValue] (
    [FanID]                      INT        NOT NULL,
    [CPOSEarning]                SMALLMONEY NOT NULL,
    [DPOSEarning]                SMALLMONEY NOT NULL,
    [DDEarning]                  SMALLMONEY NOT NULL,
    [OtherEarning]               SMALLMONEY NOT NULL,
    [CurrentAnniversaryEarning]  SMALLMONEY NOT NULL,
    [PreviousAnniversaryEarning] SMALLMONEY NOT NULL,
    CONSTRAINT [PK_Member_LifeTimeValue_FanID] PRIMARY KEY CLUSTERED ([FanID] ASC)
);

