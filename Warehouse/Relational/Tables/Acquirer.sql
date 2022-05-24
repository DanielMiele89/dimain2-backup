CREATE TABLE [Relational].[Acquirer] (
    [AcquirerID]      TINYINT      IDENTITY (1, 1) NOT NULL,
    [AcquirerName]    VARCHAR (50) NOT NULL,
    [RewardTrackable] BIT          CONSTRAINT [DF_Relational_Acquirer_RewardTrackable] DEFAULT ((0)) NOT NULL
);

