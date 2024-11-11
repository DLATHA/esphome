#include "image_decoder.h"
#include "online_image.h"
#include "esphome/core/  // Include this for PSRAM allocation functions
#include "esphome/core/log.h"

namespace esphome {
namespace online_image {

static const char *const TAG = "online_image.decoder";

class DownloadBuffer {
 public:
  DownloadBuffer(size_t size) : size_(size) {
    // Allocate the buffer in PSRAM if available
    this->buffer_ = (uint8_t *)heap_caps_malloc(size, MALLOC_CAP_SPIRAM);
    if (!this->buffer_) {
      ESP_LOGE(TAG, "Failed to allocate buffer in PSRAM. Falling back to internal RAM.");
      this->buffer_ = (uint8_t *)heap_caps_malloc(size, MALLOC_CAP_DEFAULT);
      if (!this->buffer_) {
        ESP_LOGE(TAG, "Failed to allocate buffer in internal RAM as well. Out of memory!");
      }
    }
    this->reset();
  }

  virtual ~DownloadBuffer() {
    if (this->buffer_) {
      free(this->buffer_);
    }
  }

  uint8_t *data(size_t offset = 0) {
    if (offset > this->size_) {
      ESP_LOGE(TAG, "Tried to access beyond download buffer bounds!!!");
      return this->buffer_;
    }
    return this->buffer_ + offset;
  }

  size_t read(size_t len) {
    if (len > this->unread_) {
      len = this->unread_;
    }
    this->unread_ -= len;
    if (this->unread_ > 0) {
      memmove(this->data(), this->data(len), this->unread_);
    }
    return this->unread_;
  }

  void reset() {
    this->unread_ = 0;
  }

  size_t unread() const {
    return this->unread_;
  }

  size_t size() const {
    return this->size_;
  }

  size_t free_capacity() const {
    return this->size_ - this->unread_;
  }

  uint8_t *append() {
    return this->data(this->unread_);
  }

  size_t write(size_t len) {
    this->unread_ += len;
    return this->unread_;
  }

 protected:
  uint8_t *buffer_;
  size_t size_;
  size_t unread_;
};

}  // namespace online_image
}  // namespace esphome
