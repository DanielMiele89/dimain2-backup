CREATE TABLE [APW].[DirectLoad_RetailerOnline] (
    [RetailerID] INT NOT NULL,
    [IsOnline]   BIT CONSTRAINT [DF_APW_DirectLoad_RetailerOnline] DEFAULT ((1)) NOT NULL,
    CONSTRAINT [PK_APW_DirectLoad_RetailerOnline] PRIMARY KEY CLUSTERED ([RetailerID] ASC)
);

