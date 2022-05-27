CREATE TABLE [MI].[SchemeMI_OfferExclude] (
    [ID]           TINYINT      IDENTITY (1, 1) NOT NULL,
    [DateChoiceID] TINYINT      NOT NULL,
    [ExcludeDesc]  VARCHAR (50) NOT NULL,
    [ExcludeCount] INT          NOT NULL,
    CONSTRAINT [PK_MI_SchemeMI_OfferExclude] PRIMARY KEY CLUSTERED ([ID] ASC)
);

