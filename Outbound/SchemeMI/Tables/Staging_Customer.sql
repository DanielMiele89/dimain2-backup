CREATE TABLE [SchemeMI].[Staging_Customer] (
    [FanID]                  INT          NOT NULL,
    [DOB]                    DATE         NULL,
    [ActivatedDate]          DATE         NOT NULL,
    [DeactivatedDate]        DATE         NULL,
    [OptedOutDate]           DATE         NULL,
    [GenderID]               TINYINT      NOT NULL,
    [AgeBandID]              TINYINT      NULL,
    [BankID]                 TINYINT      NULL,
    [RainbowID]              TINYINT      NULL,
    [ChannelPreferenceID]    TINYINT      CONSTRAINT [DF_ChannelPreferenceID] DEFAULT ((3)) NOT NULL,
    [JourneyStageID]         TINYINT      NULL,
    [ContactByEmail]         INT          NOT NULL,
    [ContactByPhone]         INT          NOT NULL,
    [ContactBySMS]           INT          NOT NULL,
    [ContactByPost]          INT          NOT NULL,
    [IsLapsed]               BIT          NOT NULL,
    [ActivationMethodID]     TINYINT      NOT NULL,
    [JourneyStageDetailedID] TINYINT      NOT NULL,
    [SourceUID]              VARCHAR (20) NULL,
    [EmailEngaged]           BIT          NOT NULL,
    [Registered]             BIT          NOT NULL,
    [ActivationChannel]      TINYINT      NOT NULL,
    [ClearedBalance]         MONEY        NOT NULL,
    CONSTRAINT [PK_SchemeMI_Staging_Customer_FanID] PRIMARY KEY CLUSTERED ([FanID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [ix_Stuff]
    ON [SchemeMI].[Staging_Customer]([FanID] ASC)
    INCLUDE([GenderID], [AgeBandID], [BankID], [RainbowID], [ChannelPreferenceID], [ActivationMethodID]);

