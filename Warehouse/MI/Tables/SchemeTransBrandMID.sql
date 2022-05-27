CREATE TABLE [MI].[SchemeTransBrandMID] (
    [BrandMIDID] INT  NOT NULL,
    [OutletID]   INT  NOT NULL,
    [PartnerID]  INT  NOT NULL,
    [IsOnline]   BIT  NOT NULL,
    [StartDate]  DATE NOT NULL,
    [EndDate]    DATE NULL,
    CONSTRAINT [PK_MI_SchemeTransBrandMID] PRIMARY KEY CLUSTERED ([BrandMIDID] ASC)
);

