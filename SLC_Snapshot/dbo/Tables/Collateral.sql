CREATE TABLE [dbo].[Collateral] (
    [ID]               INT            IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [CollateralTypeID] INT            NOT NULL,
    [IronOfferID]      INT            NOT NULL,
    [Text]             NVARCHAR (MAX) NULL,
    [FileName]         NVARCHAR (100) NULL,
    [DateTimeStamp]    DATETIME       NULL,
    CONSTRAINT [PK_Collateral] PRIMARY KEY CLUSTERED ([ID] ASC)
);

