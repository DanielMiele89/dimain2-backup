CREATE TABLE [Michael].[VirginWireframeMembers] (
    [FanID]         INT            NOT NULL,
    [Gender]        VARCHAR (1)    NULL,
    [DOB]           DATE           NULL,
    [Postcode]      NVARCHAR (20)  NULL,
    [PublisherID]   INT            NULL,
    [PublisherName] NVARCHAR (100) NULL,
    CONSTRAINT [PK_VirginWireframeMembers] PRIMARY KEY CLUSTERED ([FanID] ASC)
);

