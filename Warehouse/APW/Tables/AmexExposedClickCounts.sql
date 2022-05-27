CREATE TABLE [APW].[AmexExposedClickCounts] (
    [ID]            INT      IDENTITY (1, 1) NOT NULL,
    [IronOfferID]   INT      NOT NULL,
    [ReceivedDate]  DATE     NOT NULL,
    [ExposedCounts] INT      NOT NULL,
    [ClickCounts]   INT      NOT NULL,
    [ImportDate]    DATETIME CONSTRAINT [DF_Transform_AmexExposedClickCounts] DEFAULT (getdate()) NULL,
    CONSTRAINT [PK_APW_AmexExposedClickCounts] PRIMARY KEY CLUSTERED ([ID] ASC)
);

