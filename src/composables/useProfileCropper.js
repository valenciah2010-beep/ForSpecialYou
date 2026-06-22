import { ref } from 'vue';
import { clamp } from '../utils/validation.js';

export function useProfileCropper({ onApply, onError, onLoaded }) {
  const isCropperOpen = ref(false);
  const isCropDragging = ref(false);
  const cropPosition = ref({ x: 0, y: 0 });
  const cropZoom = ref(1);
  const cropPreview = ref('');
  let cropImageElement;
  let cropDragStart = {
    pointerX: 0,
    pointerY: 0,
    x: 0,
    y: 0
  };

  function openProfileImageCropper(imageSource) {
    cropPosition.value = { x: 0, y: 0 };
    cropZoom.value = 1;
    isCropDragging.value = false;
    cropPreview.value = '';
    cropImageElement = new Image();
    cropImageElement.addEventListener('load', () => {
      isCropperOpen.value = true;
      renderCropPreview();
      onLoaded?.();
    });
    cropImageElement.addEventListener('error', () => {
      onError?.('Unable to load that image.');
    });
    cropImageElement.src = imageSource;
  }

  function renderCropPreview() {
    if (!cropImageElement?.naturalWidth || !cropImageElement?.naturalHeight) return;

    const outputSize = 360;
    const canvas = document.createElement('canvas');
    const context = canvas.getContext('2d');
    if (!context) return;

    const cropSize = Math.min(cropImageElement.naturalWidth, cropImageElement.naturalHeight) / cropZoom.value;
    const maxLeft = Math.max(0, cropImageElement.naturalWidth - cropSize);
    const maxTop = Math.max(0, cropImageElement.naturalHeight - cropSize);
    const sourceX = maxLeft * ((Number(cropPosition.value.x) + 100) / 200);
    const sourceY = maxTop * ((Number(cropPosition.value.y) + 100) / 200);

    canvas.width = outputSize;
    canvas.height = outputSize;
    context.drawImage(
      cropImageElement,
      sourceX,
      sourceY,
      cropSize,
      cropSize,
      0,
      0,
      outputSize,
      outputSize
    );
    cropPreview.value = canvas.toDataURL('image/jpeg', 0.9);
  }

  function startCropDrag(event) {
    if (!cropPreview.value) return;

    isCropDragging.value = true;
    cropDragStart = {
      pointerX: event.clientX,
      pointerY: event.clientY,
      x: cropPosition.value.x,
      y: cropPosition.value.y
    };
    event.currentTarget.setPointerCapture?.(event.pointerId);
  }

  function moveCropImage(event) {
    if (!isCropDragging.value) return;

    const frameSize = event.currentTarget.getBoundingClientRect().width || 220;
    const deltaX = event.clientX - cropDragStart.pointerX;
    const deltaY = event.clientY - cropDragStart.pointerY;

    cropPosition.value = {
      x: clamp(cropDragStart.x - (deltaX / frameSize) * 200, -100, 100),
      y: clamp(cropDragStart.y - (deltaY / frameSize) * 200, -100, 100)
    };
    renderCropPreview();
  }

  function zoomCropImage(event) {
    const nextZoom = cropZoom.value + (event.deltaY < 0 ? 0.16 : -0.16);
    cropZoom.value = clamp(nextZoom, 1, 4);
    renderCropPreview();
  }

  function stopCropDrag(event) {
    if (!isCropDragging.value) return;

    isCropDragging.value = false;
    try {
      event.currentTarget.releasePointerCapture?.(event.pointerId);
    } catch {
      // The pointer may already be released when the browser fires lostpointercapture.
    }
  }

  function closeProfileImageCropper() {
    isCropperOpen.value = false;
    isCropDragging.value = false;
    cropPreview.value = '';
    cropImageElement = undefined;
  }

  function applyProfileImageCrop() {
    if (!cropPreview.value) return;

    onApply?.(cropPreview.value);
    closeProfileImageCropper();
  }

  return {
    applyProfileImageCrop,
    closeProfileImageCropper,
    cropPosition,
    cropPreview,
    cropZoom,
    isCropDragging,
    isCropperOpen,
    moveCropImage,
    openProfileImageCropper,
    startCropDrag,
    stopCropDrag,
    zoomCropImage
  };
}
