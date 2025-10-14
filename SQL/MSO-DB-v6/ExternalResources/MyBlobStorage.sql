CREATE EXTERNAL DATA SOURCE [MyBlobStorage]
    WITH (
    TYPE = BLOB_STORAGE,
    LOCATION = N'https://009storage.blob.core.windows.net/',
    CREDENTIAL = [MyBlobStorageCredential]
    );


GO

