CREATE TABLE [Staging].[Cameo_Updates] (
    [Postcode]      VARCHAR (50) NOT NULL,
    [ColumnUpdated] VARCHAR (50) NULL,
    [PreviousValue] VARCHAR (50) NULL,
    [NewValue]      VARCHAR (50) NULL,
    [UpdateDate]    DATETIME     NULL,
    CONSTRAINT [pk_Cameo_Updates_Postcode] PRIMARY KEY CLUSTERED ([Postcode] ASC)
);

