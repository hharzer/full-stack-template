import React from 'react';
import { translate as transl } from 'react-admin';

const PostTitle = transl(({ record, translate }) => (
  <span>
    {record ? translate('post.edit.title', { title: record.title }) : ''}
  </span>
));

export default PostTitle;
