"""
Celery tasks for the photo app.
"""
from celery import shared_task
import time


@shared_task
def process_uploaded_image(photo_id):
    """
    Process an uploaded image - RAM-intensive task for Kubernetes scaling testing.
    
    This task allocates more than 500MB of RAM to test Kubernetes autoscaling.
    
    Args:
        photo_id: The ID of the Photo instance that was uploaded
    """
    # Allocate memory to exceed 500MB
    # We'll allocate 600MB to be safe and ensure we exceed the 500MB threshold
    target_mb = 600
    target_bytes = target_mb * 1024 * 1024  # Convert to bytes
    
    print(f"Starting RAM-intensive task for photo_id={photo_id}")
    print(f"Allocating approximately {target_mb}MB of RAM...")
    
    # Create multiple large bytearrays to consume memory
    # Each bytearray will be 100MB, so we'll create 6 of them to get ~600MB
    large_data_structures = []
    chunk_size = 100 * 1024 * 1024  # 100MB chunks
    
    for i in range(6):
        # Create a bytearray filled with data to ensure memory is actually allocated
        chunk = bytearray(chunk_size)
        # Fill with some pattern to ensure memory pages are actually used
        for j in range(0, len(chunk), 1024):
            chunk[j] = (i + j) % 256
        large_data_structures.append(chunk)
        print(f"Allocated chunk {i+1}/6 (100MB each)")
    
    # Keep the data in memory for a while to simulate processing
    # This ensures the memory usage is sustained and visible to Kubernetes
    print(f"Memory allocated. Keeping in memory for 30 seconds...")
    time.sleep(30)  # Keep memory allocated for 30 seconds
    
    # Perform some operations to ensure the memory is actually used
    total = sum(len(chunk) for chunk in large_data_structures)
    
    print(f"Task completed for photo_id={photo_id}, total bytes allocated: {total}")
    
    # Clear the large data structures
    del large_data_structures
    
    return {
        'photo_id': photo_id,
        'status': 'processed',
        'memory_allocated_mb': target_mb
    }

