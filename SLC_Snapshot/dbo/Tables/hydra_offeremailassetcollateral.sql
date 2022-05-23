CREATE TABLE [dbo].[hydra_offeremailassetcollateral] (
    [offeremailassetcollateralid]   NVARCHAR (50)  NOT NULL,
    [offerid]                       NVARCHAR (50)  NOT NULL,
    [calltoactionurl]               NVARCHAR (150) NOT NULL,
    [emailcopy]                     NVARCHAR (650) NOT NULL,
    [emailofferheader]              NVARCHAR (100) NOT NULL,
    [emailmarketingratedisplaytext] NVARCHAR (50)  NOT NULL,
    [logo]                          NVARCHAR (150) NOT NULL,
    [logothumbnail]                 NVARCHAR (150) NOT NULL,
    [logourl]                       NVARCHAR (150) NOT NULL,
    [createddate]                   DATETIME2 (7)  NOT NULL,
    [modifieddate]                  DATETIME2 (7)  NOT NULL,
    [deleteddate]                   NVARCHAR (1)   NULL,
    [deleted]                       BIT            NOT NULL,
    CONSTRAINT [PK_hydra_offeremailassetcollateral] PRIMARY KEY CLUSTERED ([offeremailassetcollateralid] ASC)
);

