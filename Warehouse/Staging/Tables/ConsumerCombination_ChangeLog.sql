CREATE TABLE [Staging].[ConsumerCombination_ChangeLog] (
    [ID]           INT          IDENTITY (1, 1) NOT NULL,
    [BrandName]    VARCHAR (50) NULL,
    [NewOrUpdate]  VARCHAR (50) NULL,
    [BrandID]      INT          NULL,
    [DateResolved] DATE         NULL,
    [ActionedBy]   VARCHAR (50) NULL,
    [Amount_POS]   MONEY        NULL,
    [Outlets_POS]  INT          NULL,
    [Amount_DD]    MONEY        NULL,
    [Outlets_DD]   INT          NULL
);


GO
CREATE CLUSTERED INDEX [CIX_ID]
    ON [Staging].[ConsumerCombination_ChangeLog]([ID] ASC);

