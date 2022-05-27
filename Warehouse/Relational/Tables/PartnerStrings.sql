CREATE TABLE [Relational].[PartnerStrings] (
    [PartnerName]          VARCHAR (100)  NULL,
    [PartnerString]        VARCHAR (50)   NOT NULL,
    [PartnerName_Formated] VARCHAR (8000) NULL,
    [HTM_Current]          BIT            NULL,
    PRIMARY KEY CLUSTERED ([PartnerString] ASC)
);


GO
CREATE NONCLUSTERED INDEX [i_PartnerStrings_HTMCurrent]
    ON [Relational].[PartnerStrings]([HTM_Current] ASC);

