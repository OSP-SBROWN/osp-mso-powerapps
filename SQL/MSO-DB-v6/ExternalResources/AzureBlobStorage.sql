CREATE EXTERNAL DATA SOURCE [AzureBlobStorage]
    WITH (
    TYPE = BLOB_STORAGE,
    LOCATION = N'https://009storage.blob.core.windows.net',
    CREDENTIAL = [AzureBlobCredential]
    );


GO

