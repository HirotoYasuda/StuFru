<template>
  <form @submit.prevent="updateUser">
    <div class="modal fade" id="targetCommentEditModal" data-backdrop="static" tabindex="-1" role="dialog" aria-labelledby="targetCommentEditModalLabel" aria-hidden="true">
      <div class="modal-dialog modal-dialog-centered modal-dialog modal-dialog-centered-scrollable" role="document">
        <div class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title">編集</h5>
          </div>
          <div class="modal-body">
            <label class="mb-1">目標コメント</label>
            <div class="input-group">
              <textarea rows="4" class="form-control rounded" v-model="user.target_comment">自己紹介</textarea>
            </div>
          </div>
          <div class="modal-footer">
            <button type="button" class="btn btn-secondary" data-dismiss="modal">閉じる</button>
            <button type="submit" class="btn btn-primary">保存</button>
          </div>
        </div>
      </div>
    </div>
  </form>
</template>

<script>
import axios from 'axios';

export default {
  props: ['user'],
  methods: {
    updateUser: function() {
      $('#targetCommentEditModal').modal('hide');
      axios
        .patch(`/api/users/${this.$route.params.id}`, { user: { target_comment: this.user.target_comment  } } )
        .then(() => { 
          this.$parent.errors = '';
          this.$parent.flashMessage = true;
          setTimeout(() => { this.$parent.flashMessage = false}, 3000);
          })
        .catch(error => {
          if (error.response.data && error.response.data.errors) {
            this.$parent.errors = error.response.data.errors;
          }
        });
    }
  }
}
</script>

<style scoped>
</style>