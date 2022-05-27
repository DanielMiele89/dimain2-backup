CREATE TABLE [dbo].[MaintenanceDate] (
    [MaintDate] DATE           NOT NULL,
    [Comment]   VARCHAR (1024) NULL,
    CONSTRAINT [PK_MaintenanceDate_MaintDate] PRIMARY KEY CLUSTERED ([MaintDate] ASC)
);




GO
GRANT SELECT
    ON OBJECT::[dbo].[MaintenanceDate] TO [DataMart]
    AS [dbo];

