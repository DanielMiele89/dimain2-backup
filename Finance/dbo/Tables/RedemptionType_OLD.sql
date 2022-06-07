CREATE TABLE [dbo].[RedemptionType_OLD] (
    [RedemptionTypeID] SMALLINT      IDENTITY (1, 1) NOT NULL,
    [Name]             VARCHAR (25)  NOT NULL,
    [Description]      VARCHAR (200) NOT NULL,
    CONSTRAINT [PK_RedemptionType_OLD] PRIMARY KEY CLUSTERED ([RedemptionTypeID] ASC)
);

