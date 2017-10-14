import React from 'react';
import styled from 'styled-components';
import { Heading, Modal, Button } from 'react-components-kit';

import View from '~layout/view.component';

const SearchViewWrapper = styled(View)`
`;

const SearchView = ({ actions, appState }) => (
  <SearchViewWrapper
    className='SearchView'
    title='Search'
    type='fullPage'
  >
    <Modal
      visible={appState.modalVisible}
      hide={actions.onHideModal}
      backdropBg='rgba(0, 0, 0, 0.5)'
    >
      <Modal.Body>
        <Heading>Search Example</Heading>
        <p>
          This example demonstrates:
        </p>
        <ul>
          <li>React + redux + redux-saga</li>
          <li>Animations</li>
          <li>Responsive results layout</li>
          <li>Paging</li>
          <li>Caching</li>
          <li>Postgres full text search</li>
          <li>Postgres json search</li>
          <li>End-to-end tests</li>
          <li>Unit tests</li>
        </ul>
        <Modal.Footer>
          <Button flat onClick={actions.onHideModal}>Ok</Button>
        </Modal.Footer>
      </Modal.Body>
    </Modal>
  </SearchViewWrapper>
);

export default SearchView;
