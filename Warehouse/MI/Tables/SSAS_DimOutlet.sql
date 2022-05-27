CREATE TABLE [MI].[SSAS_DimOutlet] (
    [OutletID]  INT          NOT NULL,
    [PartnerID] INT          NOT NULL,
    [PostCode]  VARCHAR (20) NOT NULL,
    [Region]    VARCHAR (30) NOT NULL,
    CONSTRAINT [PK_MI_SSAS_DimOutlet] PRIMARY KEY CLUSTERED ([OutletID] ASC)
);

