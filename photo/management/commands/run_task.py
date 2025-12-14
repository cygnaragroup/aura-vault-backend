"""
Django management command to run the photo processing task.
This command is executed in Kubernetes Jobs.
"""
from django.core.management.base import BaseCommand
from photo.task_runner import run_task


class Command(BaseCommand):
    help = 'Run the photo processing task (used in Kubernetes Jobs)'

    def add_arguments(self, parser):
        parser.add_argument('photo_id', type=int, help='The ID of the Photo to process')

    def handle(self, *args, **options):
        photo_id = options['photo_id']
        self.stdout.write(self.style.SUCCESS(f'Starting task for photo_id={photo_id}'))
        
        try:
            result = run_task(photo_id)
            self.stdout.write(self.style.SUCCESS(f'Task completed: {result}'))
        except Exception as e:
            self.stdout.write(self.style.ERROR(f'Task failed: {e}'))
            raise

