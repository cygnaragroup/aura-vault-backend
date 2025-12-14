from rest_framework import generics

from .models import Photo
from .serializers import PhotoSerializer
from .tasks import process_uploaded_image


class PhotoListCreateAPIView(generics.ListCreateAPIView):
    """
    API endpoint to list and upload photos.

    - GET /photos/      -> list all photos
    - POST /photos/     -> create (upload) a new photo

    Files are stored in S3 via DEFAULT_FILE_STORAGE and metadata is saved
    in PostgreSQL.
    """

    queryset = Photo.objects.order_by("-uploaded_at")
    serializer_class = PhotoSerializer

    def perform_create(self, serializer):
        """
        Save the photo and trigger the Celery task for processing.
        """
        photo = serializer.save()
        # Trigger the Celery task asynchronously
        process_uploaded_image.delay(photo.id)

